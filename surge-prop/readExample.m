clear all; close all;

% read default configuration a single time
run('setup.m');
data = lj.read();

% scan for 10s

timed_data = lj.timedRead(5);