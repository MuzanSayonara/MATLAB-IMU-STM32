load mesure_ali.txt 

Fs = 458;
N = length(mesure_ali);
Nf = 3322


for i = 1:Nf
    for j = 0:4
    X(j+1) = mesure_ali(i+j,3) * 2.442 / ((2^31) * 1.35);
    Y(j+1) = mesure_ali(i+j,8) * 2.442 / ((2^31) * 1.35);
    Z(j+1) = mesure_ali(i+j,13) * 2.442 / ((2^31) * 1.35);
    
    Gz(j+1) = mesure_ali(i+j,18) * 4.375 / 1000;
    Gy(j+1) = mesure_ali(i+j,19) * 4.375 / 1000 ;
    Gx(j+1) = mesure_ali(i+j,20) * 4.375 / 1000 ;
    end
    
    Xm = ( X(1) + X(2) + X(3) + X(4) + X(5) ) / 5 ;
    Ym = ( Y(1) + Y(2) + Y(3) + Y(4) + Y(5) ) / 5 ;
    Zm = ( Z(1) + Z(2) + Z(3) + Z(4) + Z(5) ) / 5 ;
    
    Gzm = ( Gz(1) + Gz(2) + Gz(3) + Gz(4) + Gz(5) ) / 5 ;
    Gym = ( Gy(1) + Gy(2) + Gy(3) + Gy(4) + Gy(5) ) / 5 ;
    Gxm = ( Gx(1) + Gx(2) + Gx(3) + Gx(4) + Gx(5) ) / 5 ;
    
    allAccel(i,1) = Xm * 9.8 ;
    allAccel(i,2) = Ym * 9.8 ;
    allAccel(i,3) = Zm * 9.8 ;
    
    allGyro(i,1) = Gxm ; 
    allGyro(i,2) = Gym ;
    allGyro(i,3) = Gzm ;
    
end

numSamples = size(allAccel,1);
t = (0:(numSamples-1)).'/Fs;
figure(8)
plot(t,allAccel(:,1),'r');
hold on
plot(t,allAccel(:,2),'g');
hold on
plot(t,allAccel(:,3),'b');

save Test_Ali.mat allAccel allGyro Fs Nf
