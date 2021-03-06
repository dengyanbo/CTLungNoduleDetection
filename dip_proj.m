%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Lung Nodules Detection
%
%Author: Yanbo Deng
%April, 26th, 2015
%
%advisor: Kenji Suzuki
%Illinois Institute of Technology
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear;
clc;
close all;

I=imread('CTcase3.pgm');%change from CTcase1 to CTcase6
imshow(I);
[w,h]=size(I);

%segment the lung
%================================================
%inverse the image for filling use
invI=uint8(255-I);
invI2 = imadjust(invI);

level = graythresh(invI2);
invbw = im2bw(invI2,level);

iS = bwareaopen(invbw, 1000);
iS=imfill(iS,'holes');

OI=255*ones(w,h);
lung=find(iS==1);
OI(lung)=I(lung);

%OI is the segmented lung
%figure,
%imshow(OI,[]);

%segment the nodule
%=================================================
background = imopen(I,strel('disk',10));
I2 = I - background;
I3=imadjust(I2);

level = graythresh(I3);
bw = im2bw(I3,level);

[L,num]=bwlabel(bw,8);

S=zeros(w,h);
L_N=zeros(w,h);

%select suitable size of nodules
for i=1:num
    nodule=find(L==i);
    if(length(nodule)>=20)
        if(length(nodule)<=500)
            S(nodule)=bw(nodule);
            %the nodule must stay in the lung
            n_end=length(nodule);           
            if(ismember(nodule(1),lung)==1&&ismember(nodule(n_end),lung)==1)
                L_N(nodule)=I(nodule);
            end
        end
    end
end
%L_N is all the candidates of lung nodules

%figure,
%imshow(L_N);

%classify with the average value
%===================================================
[L2,num2]=bwlabel(L_N,8);

u=zeros(num2,1);
for i=1:num2
    xy=find(L2==i);
    u(i,1)=sum(I(xy));
end

%Eu is the threshold of average value
%usually the lung nodules are lighter than others by my observation
Eu=sum(u)/length(u);
TI=find(u>Eu);

LN=zeros(w,h);
%drawing a circle around the "nodules" with radius equals to 10
ang=0:0.01:2*pi;
radi=10;
        
figure(1),
hold on
for i=1:num2
    %if candidates are few enough(<=3), do not need to classify in case of
    %missing some of the real nodules
    if(num2<=3)
        LN=L_N;
        [x,y]=find(L2==i);
        c_x=(x(1)+x(length(x)))/2;
        c_y=(y(1)+y(length(y)))/2;
        plot(c_y+radi*cos(ang),c_x+radi*sin(ang));
        break;
    %drawing the circles roughly around the nodules to reduce the
    %complexity of computation
    elseif(ismember(i,TI))
        Tn=find(L2==i);
        [x,y]=find(L2==i);
        LN(Tn)=I(Tn);
        c_x=(x(1)+x(length(x)))/2;
        c_y=(y(1)+y(length(y)))/2;
        
        plot(c_y+radi*cos(ang),c_x+radi*sin(ang));
        
    end
end
hold off

%LN is the selected nodules
%figure,
%imshow(LN);
