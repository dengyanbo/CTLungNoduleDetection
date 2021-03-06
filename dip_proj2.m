%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Lung Nodules Detection
%version 2.0
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
image_name=['CTcase1.pgm';'CTcase2.pgm';'CTcase3.pgm';'CTcase4.pgm';'CTcase5.pgm';'CTcase6.pgm'];
cellname='A1';
cellnumber=1;
for index=1:6
    I=imread(image_name(index,:));
    figure(index),
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

    H = -fspecial('log',[25 25],6);
    I4=imfilter(I3 ,H ,'replicate');
    I5=imadjust(I4);
    level = graythresh(I5);
    bw = im2bw(I5,level);

    %figure,
    %imshow(bw);

    [L,num]=bwlabel(bw,8);

    S=zeros(w,h);
    L_N=zeros(w,h);

    %select suitable size of nodules
    for i=1:num
        nodule=find(L==i);
        if(length(nodule)>=40)
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

    %linear classification
    %========================================================
    %1st classification
    %criteria:solidity and lightness
    [L2,num2]=bwlabel(L_N,8);
    solidity=zeros(num2,1);
    lightness=zeros(num2,1);
    linear=zeros(num2,1);

    sol = regionprops(L2, 'Solidity');
    for i=1:num2
        nodule1=find(L2==i);
        A=length(nodule1); 
        solidity(i)=sol(i).Solidity;
        lightness(i)=sum(I(nodule1))/A;
        linear(i)=linear_classify(solidity(i),lightness(i));
    end
    TI1=find(linear<0);
    TI2=find(lightness>77);
    TI_=intersect(TI2,TI1);
    
    %=========================================================
    %2nd classification
    %criteria:circularity and contrast
    LN_=zeros(w,h);
    for i=1:num2     
        if(ismember(i,TI_))
            Tn=find(L2==i);
            LN_(Tn)=I(Tn);
        end
    end
    [L3,num3]=bwlabel(LN_,8);
    circularity=zeros(num3,1);
    contrast=zeros(num3,1);
    linear2=zeros(num3,1);
    
    for i=1:num3
        nodule2=find(L3==i);
        bw2=bwperim(bw(nodule2));
        contrast(i)=max(I(nodule2))-min(I(nodule2));
        p=length(bw2);
        area=length(nodule2);
        circularity(i)=4*pi*area/(p^2);
        linear2(i)=linear_classify2(circularity(i),contrast(i));
    end
    TI=find(linear2>=0);
    
    %compute the linear selection in Excel before the classification
    %=========================================================
    %text=[circularity contrast];
    %cellnumber=cellnumber+length(circularity);
    %xls=xlswrite('test2.xls',text,'sheet1',cellname);
    %cellname=['A',num2str(cellnumber)];
    %=========================================================

    LN=zeros(w,h);
    %drawing a circle around the "nodules" with radius equals to 10
    ang=0:0.01:2*pi;
    radi=10;

    %Drawing
    figure(index),
    hold on
    for i=1:num3     
        %drawing the circles roughly around the nodules to reduce the
        %complexity of computation
        if(ismember(i,TI))
            Tn=find(L3==i);
            [x,y]=find(L3==i);
            LN(Tn)=I(Tn);
            c_x=(x(1)+x(length(x)))/2;
            c_y=(y(1)+y(length(y)))/2;

            plot(c_y+radi*cos(ang),c_x+radi*sin(ang));

        end
    end
    hold off

    %LN is the selected nodules
    %figure,
    %imshow(LN,[]);
end