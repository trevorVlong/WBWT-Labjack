classdef LabjackT7 < handle
    %LABJACKT7 class for interfacing with a labjack T7 and configuring it for various tasks. 
    %   Detailed explanation goes here
    
    properties(SetAccess=private,GetAccess=public)
        % settings for .NET assembly, private because the user won't need them
        ljmAsm 
        LJM_CONSTANTS
        handle
        LJMASM 
        TIME    
    end
    
    properties(Access = public)
    % data and other relevant properties for data collection and signal output from the labjack  
        ScanRate
        ScanNum
        clock_roll_value 

    % AIN tracking
        AINChannels = []
        DIOInChannels = []
        ChannelIn = []
        numIN
        ScanList
        ScanListNames
        NETScanList
        Types

        DeviceBacklog
        LJMBacklog

        
    end
    
    methods
        
        function setup(obj)
            %LJBOX Construct an instance of this class
            %   Detailed explanation goes here
            obj.LJMASM = NET.addAssembly('Labjack.LJM');
            obj.TIME = obj.LJMASM.AssemblyHandle.GetType('LabJack.LJM+CONSTANTS');
            obj.LJM_CONSTANTS = System.Activator.CreateInstance(obj.TIME);
            
        end
        
        function connect(obj)
            % connects to a labjack T7 device
            % *** NOTE to set this up for multiple devices****
            [ljmError, obj.handle] = LabJack.LJM.OpenS('T7','ANY','ANY',0);
            
        end

        function configurePWMOuput(obj)
            % CONFIGUREPWMOUTPUT sets up the labjack to ouput a pwm signal and sets the default signal to 10ms.
            % The class is based of the example provided at https://support.labjack.com/docs/13-2-2-pwm-out-t-series-datasheet 
            %
            % sets up and starts a PWM output from Labjack, this can be changed before 
            % the start of any stream of data, and will continue until changed again
            %
            % ***NOTE***  best practice is to always set motors back to 0 after each run
            % otherwise, it is likely that they will burn out if at high RPMs
            % 
            % this setup function will always intialize a motor at PWM = 1000, function below
            % will change the actual
            %
            % channel is always outputting PWM signal after DIO0,EF_ENABLE,1 line
            name = "DIO0"; % channel 

            % set Clock0 roll value for 50 Hz output signal, T7 clock runs at 160Mhz
            obj.clock_roll_value = 160000; % length of the pwm signal  
            LabJack.LJM.eWriteName(obj.handle,"DIO_EF_CLOCK0_ENABLE",0);
            LabJack.LJM.eWriteName(obj.handle,'DIO_EF_CLOCK0_DIVISOR',1);
            LabJack.LJM.eWriteName(obj.handle,"DIO_EF_CLOCK0_ROLL_VALUE",obj.clock_roll_value)
            LabJack.LJM.eWriteName(obj.handle,"DIO_EF_CLOCK0_ENABLE",1);
            
            % set intitial value to PWM = 1000
            % set low value
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_ENABLE",name),0); 	%// Disable the EF system for initial configuration
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_INDEX",name), 0); 	%// Configure EF system for PWM
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_OPTIONS", name),000); 	%// Configure what clock source to use Clock0
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_CONFIG_A",name), 80*1000); 	%// Configure duty cycle to be slightly less than 1000
            LabJack.LJM.eWriteName(obj.handle, sprintf("%s_EF_ENABLE",name), 1); 	%// Enable the EF system, PWM wave is now being outputted
            
            %DUTY cycle info
            % 80000 ~ 1000 PWM, 16000 ~ 2000 PWM (slightly less)
            % states 1 = output_high, 0 = output_low
            %LabJack.LJM.eWriteName(handle,name,state)
        end
 
% set up or changre PWM out        
        function setPWM(obj,PWM)
            %SETPWM sets the pwm output signal to the desired value on DIO0
            % changes the PWM output from the labjack to specified value
            % channel is streaming the whole time
             
            LabJack.LJM.eWriteName(obj.handle,"DIO0_EF_ENABLE",0);
            LabJack.LJM.eWriteName(obj.handle,"DIO0_EF_INDEX", 0); 	%// Configure EF system for PWM
            LabJack.LJM.eWriteName(obj.handle, "DIO0_EF_OPTIONS",000); 	%// Configure what clock source to use: Clock0
            LabJack.LJM.eWriteName(obj.handle, "DIO0_EF_CONFIG_A", 80*PWM);
            LabJack.LJM.eWriteName(obj.handle,"DIO0_EF_ENABLE",1);
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
            obj.numIN = 3; % number of total inputs to record
            obj.cScanListNames = NET.createArray('System.String',obj.numIN+1);
            obj.cTypes = NET.createArray('System.Int32',obj.numIN);
            obj.cScanList = NET.createArray('System.Int32',obj.numIN);
            

            obj.cScanListNames(1) = 'AIN0';
            obj.cScanListNames(2) = 'AIN1';
            obj.cScanListNames(3) = 'DIO1_EF_READ_A_AND_RESET';
            obj.cScanListNames(4) = 'STREAM_DATA_CAPTURE_16'; % I forget what this does, but I think it's accuracy

            
            % get LabJack address for inputs above
            LabJack.LJM.NamesToAddresses(obj.numIN,obj.cScanListNames,obj.cScanList,obj.cTypes)


            % set up DIO1 to count pulses (to count RPM)
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

        function obj = SetDIOCounter(obj)
            % SETDIOCOUNTER configures DIO1 to  be a counter port and adds it to DIO1 in tracking
            % set up DIO1 to count pulses (to count RPM)

            try
                LabJack.LJM.eWriteName(obj.handle,sprintf('DIO1_EF_ENABLE'),0);
                Labjack.LJM.eWriteName(obj.handle,sprintf('DIO1_EF_INDEX'),8);
                LabJack.LJM.eWriteName(obj.handle,sprintf('DIO1_EF_ENABLE'),1);
                obj.DIOInChannels = [obj.DIOInChannels, 'DIO1'];
            catch e 
                disp(e);
            end


        end


        function obj = AINSingleEnded(obj, channel_name)
            % CONFIGUREAINSINGLEENDED configures selected AIN channels to read +/- 10V signals. 
            % 
            % 
            % 
            numFrames = 4;
            
            aNames = NET.createArray('System.String', numFrames);
            aNames(1) = sprintf('%s_NEGATIVE_CH',channel_name);
            aNames(2) = sprintf('%s_RANGE',channel_name);
            aNames(3) = sprintf('%s_RESOLUTION_INDEX',channel_name);
            aNames(4) = sprintf('%s_SETTLING_US',channel_name);
            aValues = NET.createArray('System.Double', numFrames);
            aValues(1) = 199;
            aValues(2) = 10;
            aValues(3) = 0;
            aValues(4) = 0;

            LabJack.LJM.eWriteNames(obj.handle, numFrames, aNames, aValues, 0);
            obj.AINChannels = [obj.AINChannels, channel_name];
            
            disp('----------------------------------------------------------')
            disp('Set configuration:');
            for i = 1:numFrames
                disp(['  ' char(aNames(i)) ': ' num2str(aValues(i))])
            end
            disp('----------------------------------------------------------')
            
        end

        function obj = multiAINSingleEnded(obj,channel_names)
            %MULTIAINSINGLENDED configures all channels in channel_names to read single-ended +/-10V signals
            for channel_num = 1:length(channel_names)
                % confiure channel and add to tracking list, otherwise display error
                try
                    obj.AINSingleEnded(channel_names(channel_num));
                    obj.AINChannels = [obj.AINChannels,channel_names(channel_num)];
                catch e 
                    disp(e);
                end
            end
        end

        function obj = resetScanList(obj)
            % reset all trackers for which channels are going to be read
            obj.AINChannels = [];
            obj.DIOInChannels = [];
            obj.ChannelIn = [];
        
        end
        
        function obj = configureStream(obj,scan_rate)
            % configure .NET arrays / labjack for scanning. Stores some .NET arrays for sending to labjack
            
            % set scan rate in Hz [1-60000]
            obj.ScanRate = scan_rate;

            % set the scan list based on DIO / AIN channels in
            % configuration list
            obj.ChannelIn = [obj.AINChannels, obj.DIOInChannels];
            obj.numIN = length(obj.ChannelIn);
            
            % create NET arrays, fill out ScanList
            obj.NETScanList = NET.createArray('System.Int32',obj.numIN);
            obj.Types = NET.createArray('System.Int32',obj.numIN);
            obj.ScanListNames = NET.createArray('System.String',obj.numIN);
            for idx = 1:obj.numIN
                obj.ScanListNames(idx) = sprintf("%s",obj.ChannelIn(idx));
            end
            
            % get addresses from names
            LabJack.LJM.NamesToAddresses(obj.numIN,obj.ScanListNames,obj.NETScanList,obj.Types)

            % set stream resolution (1 for speed, 8 for accuracy)
            LabJack.LJM.eWriteName(obj.handle,'STREAM_RESOLUTION_INDEX',1)
        end
        

        function data = streamBurst(obj,scantime_in_s)
            % STREAMBURST sets the labjack to record data on all active channels for a set amount of time and 
            % the rate in class settings. The total number of measurements will  
            %
            % INPUTS:
            % :scantime int: [s] time to scan 
            %

            % set up scan rate / storage .NET array, create data array
            scanNum = obj.ScanRate*scantime_in_s;
            netdata = NET.createArray('System.Double',scanNum*obj.numIN);

            % run scan
            fprintf('-----------------------------------------------------------------------\n')
            fprintf('Running stream burst with a scantime of %3.1d s and scanrate %i...\n',scantime,obj.ScanRate)
            fprintf('-----------------------------------------------------------------------\n')
            [err, ~, deviceBacklog, ljmBacklog] = LabJack.LJM.StreamBurst(obj.handle, obj.numIN, obj.NETScanList, obj.ScanRate, scanNum, netdata);  

            % reshape data for export as an MxN vector where M is number of read channels and N is the number of scans for those channels
            for idx = 1:scanNum
                data(idx) = netdata(idx);
            end
            data = reshape(data,obj.numIN,[]);

            fprintf('Stream Complete\n');
            fprintf('Device Backlog: %d\n',deviceBacklog);
            fprintf('LJM Backlog: %d\n',ljmBacklog);
            fprintf('Error Status: %d \n',err)
            fprintf('-----------------------------------------------------------------------\n')
            fprintf('-----------------------------------------------------------------------\n')
        end
        
    end
end

