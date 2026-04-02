
function SCRAMBLE_FACES

%% Editted by Thomas Faherty, March 2022 %%

clear all;
close all;
clc

% Set grid size

gridSize=15;

% Load images to be scrambled

all_images = dir('*.jpg'); % Load images

o = length(all_images); % Number of images to be scrambled

for h=1:o

currentimg = imread(all_images(h).name); % load image
all_images(h).name
currentimg = imresize(currentimg,[762,562]); %resize image


[Himg,Wimg,~] = size(currentimg);

% the scrambling procedure will take pxxsq by pzzsq grids of the image and shuffle

pxxsq = 4; % how big one square is

nSqH = Himg/pxxsq;
nSqW = Wimg/pxxsq;

k = 1;
for i = 1:nSqW
    for j = 1:nSqH;
    nSq_idx(k) = sub2ind([nSqH,nSqW],j,i);
    k = k+1;
    end
end
nSq_idx_scrambled = nSq_idx(randperm(length(nSq_idx)));

new_img = currentimg;
layer1 = currentimg(:,:,1);
layer2 = currentimg(:,:,2);
layer3 = currentimg(:,:,3);
newLayer1 = layer1;
newLayer2 = layer2;
newLayer3 = layer3;

k = 1;
for iSq = 1:nSqW;
    for jSq = 1:nSqH;
        [I,J] = ind2sub([nSqH,nSqW],nSq_idx_scrambled(k));
        thisX = pxxsq*(iSq-1)+1:pxxsq*(iSq-1)+pxxsq;
        thisY = pxxsq*(jSq-1)+1:pxxsq*(jSq-1)+pxxsq;
        newX = pxxsq*(J-1)+1:pxxsq*(J-1)+pxxsq;
        newY = pxxsq*(I-1)+1:pxxsq*(I-1)+pxxsq;

        new_img(thisY,thisX) = currentimg(newY,newX);

        newLayer1(thisY,thisX) = layer1(newY,newX);
        newLayer2(thisY,thisX) = layer2(newY,newX);
        newLayer3(thisY,thisX) = layer3(newY,newX);
        
        k = k + 1;
    end
end

old_img2 = cat(3,layer1,layer2,layer3);
new_img2 = cat(3,newLayer1,newLayer2,newLayer3);
        
%figure(1); imshow(old_img2)
%figure(2); imshow(new_img2)

imwrite(new_img2,sprintf('scrambled_%s', (all_images(h).name))); % saves images

% Clear variables

clearvars -except gridSize all_images o h

end

end