%%
%Volterra NLMS Equalyzer using PAM symbols, different evaluation of SNR and of
%the nonlinearity



clear;
clc;
close all;

addpath(['..' filesep '..' filesep 'Channel results']);
addpath(['..' filesep 'VLC Simulator' filesep]);
addpath(['..' filesep 'VLC Simulator' filesep 'LED Parameters']);

load whiteLED_334-15.mat;

% load channel01.mat;



% R = 0.56;
% R = 1;
% 
% 
% b0 = 1;
% b1 = 0.5;
% b2 = 0.05;

%-------------------------Adaptive Filtering Parameters--------------------
numberOfBits = 2;
N = 12;
maxRuns = 15000;
maxIt = 1000;
gamma = 1e-12;
SNR = 30;
mu = 0.8;
adapFiltLength = N;


auxMatrix = triu(ones(N));
[l1,l2] = find(auxMatrix);

delayVector = 14;

% delayVector = 1:15;


% noisePower = 100;
% % barGamma = 4*sqrt(5*noisePower);
% 
% barGamma = 0;
% 
barGammaVector = 1;

%-------------------------Adaptive Filtering Parameters--------------------


% SNR = 30;
% numberOfBits = 2;
% bitRate = 1e4;
% 
% 
% % h = decimate(h{1},analogChannelRate/bitRate);
% 
% 
% nonLinearity = @(x,y) b0 + b1*(x-y) + b2.*(x-y).^2;  
% % nonLinearity = @(x,y) x;
% 
% 
% h = 1;
% 
% h = [1 0.2 -0.3];
% 
% 
% % 
% % adapFiltLength = (N^2+N)/2 + N;
% % 
% % % adapFiltLength = N;
% % 
% 
% % auxMatrix = triu(ones(N));
% % [l1,l2] = find(auxMatrix);
% 
% % h = [0.34-(0.27*1i) 0.87+(0.43*1i) 0.34-(0.21*1i)]; 
% 
% % L = round((adapFiltLength + length(h))/2);
% 
% signalPower = 1;
% noisePower = signalPower/db2pow(30);


%-------------------------LED Parameters-----------------------------------
maxLEDVoltage = 3.6; %500 mV
minLEDVoltage = 3;
maxLEDCurrent = 0.03; %500 mA
minLEDCurrent = 0.004; %500 mA

maxElectricalPower = maxLEDVoltage*maxLEDCurrent;
minElectricalPower = minLEDCurrent*minLEDVoltage;
% TOV = 0.2; 
% eletrical2OpticalGain = 1; %eletrical to optical gain imposed by the LED

ISat = ISat;
VB = 2.6; %minimum voltage for current flow 
nLED = n; %LED ideality factor
VT = 0.025; %Thermal voltage


halfAngleLED = deg2rad(15);
luminousIntensityLED = 21375; %milicandela
maxLuminousIntensityLED = 28500;%milicandela

% opticalPower = luminousIntensityLED*2*pi*(1-cos(halfAngleLED))/1000;

% ledLuminousEfficacy = opticalPower/(3.2*10e-3); %this electrical power is evaluated using current and voltage of the linear region of the I-V curve%
maxCd = 28.5;
minCd = 14.25;




% ledLuminousEfficacy = opticalPower/(3.2*10e-3); %this electrical power is evaluated using current and voltage of the linear region of the I-V curve%
ledLuminousEfficacy = (maxCd - minCd)/(maxElectricalPower - minElectricalPower) ; %this electrical power is evaluated using current and voltage of the linear region of the I-V curve%


fs = 2e6;

% f = fs/2*linspace(0,1,1000) *2*pi;
% 
% w = [-fliplr(f(2:end-1)) f];
% 
% LEDResp = freqRespLED(w);




%  NFFT = 2^nextpow2(length(LEDResp)); % Next power of 2 from length of y
% %                 Y = fft(noise,length(LEDResp))/length(LEDResp);
%                 f = fs/2*linspace(0,1,length(LEDResp));
% 
%                 % Plot single-sided amplitude spectrum.
%                 figure;
%                 plot(f,20*log10((LEDResp(1:length(LEDResp)))) )
% 


Poptical = @(ledLuminousEfficacy,electricalPower,k) (ledLuminousEfficacy.*electricalPower)./((1 + (ledLuminousEfficacy.*electricalPower./(maxLuminousIntensityLED/1000)).^(2*k)).^(1/(2*k)));

%-------------------------LED Parameters-----------------------------------





%-------------------------Photodiode Parameters----------------------------

A = 1e-4; %photodiode area (cm)
d = 10e-2; %distance between LED and photodiode (cm)
R = 0.5;
FOV = deg2rad(25);

%-------------------------Photodiode Parameters----------------------------


%-------------------------Pre Amplifier Parameters-------------------------

% transimpedanceGain = 1;

%-------------------------Pre Amplifier Parameters-------------------------


%-------------------------Transmission Parameters--------------------------

kNonLinearity = 2;


% bitRate = 1e6; %1 Mb/s

theta = 0;
phi = 0;

n = -log(2)/log(cos(halfAngleLED));

H_0 = A/d^2 * (n+1)/(2*pi) * cos(phi)^n * cos(theta) * rectangularPulse(-1,1,theta/FOV);


VDC = 3.25; 
maxAbsoluteValueModulation = 3;

maxModulationIndex = (maxLEDVoltage - VDC)/VDC;

% modulationIndexVector = 0.01:0.02:maxModulationIndex;
modulationIndexVector = [0.05 0.075 0.1];

%-------------------------Transmission Parameters--------------------------



for index = 1:length(modulationIndexVector)
    
    modulationIndex = modulationIndexVector(index);
    
    if modulationIndex > maxModulationIndex
        warning('Modulation Index may cause undesired nonlinear effects')
    end

    maxVoltage = VDC*(1+modulationIndex);
    deltaV = maxVoltage - VDC;


    VoltageConstant = modulationIndex*maxVoltage/((1+modulationIndex)*maxAbsoluteValueModulation);


    for barGammaIndex = 1:length(barGammaVector)
        count = zeros(maxIt,1);

    %     count = zeros(maxIt,length(barGammaVector));
        for delay = 1:length(delayVector)

            for L = 0:0

                u = zeros(L+1,1);
                u(1) = 1;


                w2 = zeros(adapFiltLength,maxRuns,maxIt);
                for j = 1:maxIt
                    j


                    input = randi([0,2^numberOfBits-1],maxRuns*2,1);
                    pilot = real(pammod(input,2^numberOfBits,0,'gray'));

%                     Vin = pilot*VoltageConstant + VDC; %Using symbols to modulate voltage
                    Vin = pilot;

                    convLength = length(Vin) + 1000 -1;
                    NFFT = 2^nextpow2(convLength);

                    VinFreq = fft(Vin,NFFT);

                    f = fs/2*linspace(0,1,NFFT/2 + 1)  *2*pi;

                    w = [-fliplr(f(2:end-1)) f];

                    LEDResp = freqRespLED(w);

                    filteredVinAux = real(ifft(VinFreq.*fftshift(LEDResp))); 

                    filteredVin = filteredVinAux(1:length(Vin));
                    
                    VoltageConstant = modulationIndex*maxVoltage/((1+modulationIndex)*max(filteredVin));
                
                    Vin = filteredVin*VoltageConstant + VDC;
                    filteredVin = Vin;




    %                 iLEDOutput = ledModel(I_V_Fun,Vin,maxLEDVoltage,kNonLinearity);

                    iLEDOutput = I_V_Fun(filteredVin,VT,nLED,ISat);

    %                 iLEDOutput = Vin;

    %                 iLEDOutput = 1;

                    eletricalPowerOutput = filteredVin.*iLEDOutput;



    %                 opticalPowerOutput = eletrical2OpticalGain*eletricalPowerOutput;

                    opticalPowerOutput = Poptical(ledLuminousEfficacy,eletricalPowerOutput,kNonLinearity);

                    opticalPowerOutputConvolved = opticalPowerOutput*H_0;

                    n = randn(length(opticalPowerOutputConvolved),1); %noise signal

                    receivedCurrentSignal = opticalPowerOutputConvolved*R*A;
                    receivedCurrentSignalAC = receivedCurrentSignal - mean(receivedCurrentSignal);
                    receivedCurrentSignalPower = receivedCurrentSignalAC'*receivedCurrentSignalAC/length(receivedCurrentSignal);

                    powerNoiseAux = n'*n/(length(n));
                    powerNoise = (receivedCurrentSignalPower/db2pow(SNR));
                    n = n.*sqrt(powerNoise/powerNoiseAux);

    %                 

                    receivedVoltageSignalAux = (receivedCurrentSignal + n);
                    receivedVoltageSignalAux = receivedVoltageSignalAux - mean(receivedVoltageSignalAux);
                    transimpedanceGain = maxAbsoluteValueModulation/max(receivedVoltageSignalAux);
                    receivedVoltageSignal =  receivedVoltageSignalAux*sqrt(var(pilot)/var(receivedVoltageSignalAux));
                    
                    

                    unbiasedReceivedVoltageSignal = receivedVoltageSignal - VDC;

                    xAux = [zeros(N-1,1);receivedVoltageSignal];

                    w = zeros(adapFiltLength,maxRuns);

        %                 w = zeros(N,maxRuns); 
%                     pilot = Vin;


                    for k = (adapFiltLength + delayVector(delay) + L + 10):maxRuns + adapFiltLength + delayVector(delay) + L + 10 + 1


                        xAP = zeros(N,L+1);

                        for l = 0:L
                            xAP(:,l+1) = xAux(k-l:-1:k-N+1-l);
                        end

    %             

                        d(k) = (pilot(-delayVector(delay) + k + 1)); 

                        y(k) = w(:,k)'*xAP;
                        e(k) = d(k) - y(k);
                        
                        
                        w(:,k+1) = w(:,k) + mu*xAP*((xAP'*xAP+gamma*eye(L+1))\eye(L+1))*conj(e(k))*u;

                        absoluteValueError = abs(e(k));
    % 
                    end
                    w2(:,:,j) = conj(w(:,1:maxRuns));
                    e2(:,j) = abs(e).^2;
                end

                meanCount(barGammaIndex) = mean(count);

    %             count = zeros(maxIt,1);

                w3 = mean(w2,3);
                wFinal(index,barGammaIndex,delay,:,L+1) = w3(:,end);

                e3(index,barGammaIndex,delay,:,L+1) = mean(e2,2);

            end
            % save(['.' filesep 'results' filesep 'results07.mat'],'wFinal','e3','meanCount');




        %     end

        end

    end

end
% for i = 1:length(delayVector)
%     figure
% plot(10*log10((e3(i,:))))
% xlabel('Iterations','interpreter','latex');
% ylabel('MSE (dB)','interpreter','latex');
% 
% end


% for i = 1:adapFiltLength+10
%     plot(10*log10((e3(i,:,1))))
%     xlabel('Iterations','interpreter','latex');
%     ylabel('MSE (dB)','interpreter','latex');
%     hold on;
% end


save(['.' filesep 'resultsMSE_VLC' filesep 'results29.mat'],'wFinal','e3','meanCount');



rmpath(['..' filesep 'VLC Simulator' filesep]);
rmpath(['..' filesep '..' filesep 'Channel results']);
rmpath(['..' filesep 'VLC Simulator' filesep 'LED Parameters']);




