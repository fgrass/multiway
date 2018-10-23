%% Load data
clear
startup
imgset = 'Winebottle'; %'Car','Duck','Face','Motorbike','Winebottle'
datapath = sprintf('dataset/WILLOW-ObjectClass/%s/',imgset);
savepath = sprintf('result/willow/%s',imgset);
if ~exist(savepath, 'dir')
    mkdir(savepath);
end
savefile = sprintf('%s/match_kpts.mat',savepath);
imgList = dir([datapath,'*.png']);
imgList = {imgList.name};
viewList = dir([datapath,'*hypercols_kpts.mat']);
viewList = {viewList.name};
% if show match
showmatch = true;
%% pairwise matching
if exist(savefile,'file')
    load(savefile,'pMatch');
else
    % to apply linear matching, set 'wEdge' as 0
    pMatch = runGraphMatchBatch(datapath,viewList,'all',[],'wEdge',0.5,'thscore',0);
    save(savefile,'pMatch');
end
%% construct coordinate matrix C:2*m
C = [];
for i = 1:length(viewList)
    views(i) = load(sprintf('%s/%s',datapath,viewList{i}));
    cnt(:,i) = sum(views(i).frame,2)/double(views(i).nfeature);
    C = [C,views(i).frame - repmat(cnt(:,i),1,views(i).nfeature)];
end
%% Multi-Object Matching
% methods to try:
%  - 'pg': the proposed method, 
%         [Multi-Image Semantic Matching by Mining Consistent Features, CVPR 2018]
%  - 'spectral': Spectral method,
%          [Solving the multi-way matching problem by permutation synchronization, NIPS 2013]
%  - 'matchlift': MatchLift,
%          [Near-optimal joint object matching via convex relaxation, ICML 2014]   
%  - 'als': MatchALS,
%         [Multi-Image Matching via Fast Alternating Minimization, CVPR 2015]   
[jMatch,jmInfo] = runJointMatch(pMatch,C,'Method','pg','univsize',10,...
    'rank',3,'lambda',2);
% save(savefile,'-append','jMatch','jmInfo');
%% Evaluate
X1 = pMatch2perm(pMatch); % pairwise matching result
X2 = pMatch2perm(jMatch); % joint matching result
n_img = length(imgList);
n_pts = length(X1)/n_img;
X0 = sparse(repmat(eye(ceil(n_pts)),n_img,n_img)); %groundtruth
% evaluate [overlap, precision, recall]
[o1,p1,r1] = evalMMatch(X1,X0);
[o2,p2,r2] = evalMMatch(X2,X0);
%% Visualize
if showmatch
    %view pairwise matches
    for i = 1:size(pMatch,1)
        for j = i+1:size(pMatch,2)
            clf;
            if ~isempty(pMatch(i,j).X)
                if isdiag(X1((i-1)*10+1:i*10,(j-1)*10+1:j*10)) &&  isdiag(X2((i-1)*10+1:i*10,(j-1)*10+1:j*10)) 
                    continue
                end
                subplot('position',[0 0.5 1 0.48]);
                visPMatchGT(datapath,pMatch(i,j),3,'th',0.01);
                subplot('position',[0 0 1 0.48]);
                visPMatchGT(datapath,jMatch(i,j),3,'th',0.01);
                fprintf('%d-%d\n',i,j);
                pause
            end
        end
    end
end