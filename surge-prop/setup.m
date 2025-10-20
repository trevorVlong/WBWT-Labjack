% setup for 3x2 prop test for Surge 

% add path to drivers
addpath('C:/Users/2x3/Desktop/WBWT-Labjack/');

% setup T7 for 2AIN, 1 DIO in counter, and 1 PWm output
lj = LabjackT7();
lj.setup();
lj.connect();

lj.multiAINSingleEnded(["AIN0","AIN1"]);
lj.setupCounter();
lj.configurePWMOuput();
lj.setPWM(1000); % arm motor
lj.configureStream(200); % configure stream to 200Hz on each channel (600Hz total)
