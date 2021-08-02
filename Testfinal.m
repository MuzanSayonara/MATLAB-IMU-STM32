close all
clear all

samplesPerRead = 5;
runTime = 20;
isVerbose = false;

load('Test_Ali_th.mat', 'allAccel', 'allGyro','Nf','Fs')
    
numSamples = Nf ;
time = (0:(numSamples-1)).'/Fs;

%% Align Axes of MPU-9250 Sensor with NED Coordinates
% The axes of the accelerometer, gyroscope, and magnetometer in the
% MPU-9250 are not aligned with each other. Specify the index and sign x-,
% y-, and z-axis of each sensor so that the sensor is aligned with the
% North-East-Down (NED) coordinate system when it is at rest. In this
% example, the magnetometer axes are changed while the accelerometer and
% gyroscope axes remain fixed. For your own applications, change the
% following parameters as necessary.

% Accelerometer axes parameters.
accelXAxisIndex = 1;
accelXAxisSign = 1;
accelYAxisIndex = 2;
accelYAxisSign = 1;
accelZAxisIndex = 3;
accelZAxisSign = 1;

% Gyroscope axes parameters.
gyroXAxisIndex = 1;
gyroXAxisSign = 1;
gyroYAxisIndex = 2;
gyroYAxisSign = -1;
gyroZAxisIndex = 3;
gyroZAxisSign = 1;

% Magnetometer axes parameters.
%magXAxisIndex = 1;
%magXAxisSign = 1;
%magYAxisIndex = 2;
%magYAxisSign = 1;
%magZAxisIndex = 3;
%magZAxisSign = -1;

% Helper functions used to align sensor data axes.

alignAccelAxes = @(in) [accelXAxisSign, accelYAxisSign, accelZAxisSign] ...
    .* in(:, [accelXAxisIndex, accelYAxisIndex, accelZAxisIndex]);

alignGyroAxes = @(in) [gyroXAxisSign, gyroYAxisSign, gyroZAxisSign] ...
    .* in(:, [gyroXAxisIndex, gyroYAxisIndex, gyroZAxisIndex]);

%alignMagAxes = @(in) [magXAxisSign, magYAxisSign, magZAxisSign] ...
    %.* in(:, [magXAxisIndex, magYAxisIndex, magZAxisIndex]);

%% Specify Complementary filter Parameters
% The |complementaryFilter| has two tunable parameters. The
% |AccelerometerGain| parameter determines how much the accelerometer
% measurement is trusted over the gyroscope measurement. The
% |MagnetometerGain| parameter determines how much the magnetometer
% measurement is trusted over the gyroscope measurement.
IMU = imuSensor('accel-gyro','SampleRate',Fs);
aFilter = imufilter('SampleRate',Fs);
compFilt = complementaryFilter('AccelerometerGain',0.1,'HasMagnetometer', false);
%%

orientation = zeros(numSamples,1,'quaternion');
for i = 1:numSamples
    
    [accelBody,gyroBody] = IMU(allAccel(i,:),allGyro(i,:));
    
    orientation(i) = aFilter(accelBody,gyroBody);

end
release(aFilter)
figure(1)
subplot(221);
plot(time,eulerd(orientation,'XYZ','frame'))
xlabel('Time (s)')
ylabel('Rotation (degrees)')
title('Orientation Estimation -- Ideal IMU Data, Default IMU Filter')
legend('X-axis','Y-axis','Z-axis')

%%

orientationcomp = zeros(numSamples,1,'quaternion');
for i = 1:numSamples
    
    [accelBody,gyroBody] = IMU(allAccel(i,:),allGyro(i,:));
    
    orientationcomp(i) = compFilt(accelBody,gyroBody);

end
release(compFilt)

subplot(222);
plot(time,eulerd(orientation,'XYZ','frame'))
xlabel('Time (s)')
ylabel('Rotation (degrees)')
title('Orientation Estimation -- Default Complimentary')
legend('X-axis','Y-axis','Z-axis')
%%
IMU.Accelerometer = accelparams( ...
    'MeasurementRange',19.62, ...
    'Resolution',0.00059875, ...
    'ConstantBias',0.4905, ...
    'AxesMisalignment',0, ...
    'NoiseDensity',0, ...
    'BiasInstability',0, ...
    'TemperatureBias', [0.34335 0.34335 0.5886], ...
    'TemperatureScaleFactor',0.02);
IMU.Gyroscope = gyroparams( ...
    'MeasurementRange',4.3633, ...
    'Resolution',0.00013323, ...
    'AxesMisalignment',0, ...
    'NoiseDensity',0, ...
    'TemperatureBias',0.34907, ...
    'TemperatureScaleFactor',0.02, ...
    'AccelerationBias',0, ...
    'ConstantBias',[0.3491,0.5,0]);

orientationDefault = zeros(numSamples,1,'quaternion');
for i = 1:numSamples
    
    [accelBody,gyroBody] = IMU(allAccel(i,:),allGyro(i,:));
    
    orientationDefault(i) = aFilter(accelBody,gyroBody);
    
end
release(aFilter)
subplot(223)
plot(time,eulerd(orientationDefault,'XYZ','frame'))
xlabel('Time (s)')
ylabel('Rotation (degrees)')
title('Orientation Estimation -- Realistic IMU Data, Default IMU Filter')
legend('X-axis','Y-axis','Z-axis')
%%
% The ability of the |imufilter| to track the ground-truth data is
% significantly reduced when modeling a realistic IMU. To improve
% performance, modify properties of your |imufilter| object. These values
% were determined empirically. Run the loop again and plot the orientation
% estimate over time.
%

aFilter.GyroscopeNoise          = 7.6154e-7;
aFilter.AccelerometerNoise      = 0.0015398;
aFilter.GyroscopeDriftNoise     = 3.0462e-12;
aFilter.LinearAccelerationNoise = 0.00096236;
aFilter.InitialProcessNoise     = aFilter.InitialProcessNoise*10;

orientationNondefault = zeros(numSamples,1,'quaternion');
for i = 1:numSamples
    [accelBody,gyroBody] = IMU(allAccel(i,:),allGyro(i,:));
    
    orientationNondefault(i) = aFilter(accelBody,gyroBody);
end
release(aFilter)

%subplot(224);
%plot(time,eulerd(orientationNondefault,'XYZ','frame'))
%xlabel('Time (s)')
%ylabel('Rotation (degrees)')
%title('Orientation Estimation -- Realistic IMU Data, Nondefault IMU Filter')
%legend('X-axis','Y-axis','Z-axis')
%% Estimate Orientation with Accelerometer and Gyroscope
% Set the |HasMagnetometer| property to |false| to disable the magnetometer
% measurement input. In this mode, the filter only takes accelerometer and
% gyroscope measurements as inputs. Also, the filter assumes the initial
% orientation of the IMU is aligned with the parent navigation frame. If
% the IMU is not aligned with the navigation frame initially, there will be
% a constant offset in the orientation estimation.


tuner = HelperOrientationFilterTuner(compFilt);

idx = 1:samplesPerRead;
overrunIdx = 1;

while true
    accel = allAccel(idx,:);
    gyro = allGyro(idx,:);
    t = time(idx,:);
    

    idx = idx + samplesPerRead;
    
    pause(samplesPerRead/Fs)
    
    q = compFilt(accel, gyro);
    update(tuner, q);
    if idx(end) > Nf
            break;
    end
end
%%
orientation = zeros(numSamples,1,'quaternion');
for i = 1:numSamples
    
    [accelBody,gyroBody] = IMU(allAccel(i,:),allGyro(i,:));
    
    orientationcomp(i) = compFilt(accelBody,gyroBody);

end
%%
RotationRes = rotvecd(orientationcomp);
figure(4);
plot(time,RotationRes(:,1),'r');
hold on
plot(time,RotationRes(:,2),'g');
hold on
plot(time,RotationRes(:,3),'b');
xlabel('Time (s)')
ylabel('rad')
legend('X-axis','Y-axis','Z-axis');
title("Compfilter's Rotation Vector");

%%
ResultsComp = compact(orientationcomp);
figure(5)
subplot(221)
plot(time,ResultsComp(:,1),'r')
xlabel('Time (s)')
ylabel('Quaternion Value')
legend('v')
subplot(222)
plot(time,ResultsComp(:,2),'g')
xlabel('Time (s)')
ylabel('Quaternion Value')
legend('i')
subplot(223)
plot(time,ResultsComp(:,3),'b')
xlabel('Time (s)')
ylabel('Quaternion Value')
legend('j')
subplot(224)
plot(time,ResultsComp(:,4),'y')
xlabel('Time (s)')
ylabel('Quaternion Value')
legend('k')


