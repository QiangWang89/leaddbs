function cs_fmri_conseed_pmap(dfold,cname,sfile,cmd,writeoutsinglefiles,outputfolder,outputmask)

tic

% if ~isdeployed
%     addpath(genpath('/autofs/cluster/nimlab/connectomes/software/lead_dbs'));
%     addpath('/autofs/cluster/nimlab/connectomes/software/spm12');
% end

if ~exist('writeoutsinglefiles','var')
    writeoutsinglefiles=0;
else
    if ischar(writeoutsinglefiles)
        writeoutsinglefiles=str2double(writeoutsinglefiles);
    end
end


if ~exist('dfold','var')
    dfold=''; % assume all data needed is stored here.
else
    if ~strcmp(dfold(end),filesep)
        dfold=[dfold,filesep];
    end
end

disp(['Connectome dataset: ',cname,'.']);
ocname=cname;
if ismember('>',cname)
    delim=strfind(cname,'>');
    subset=cname(delim+1:end);
    cname=cname(1:delim-1);
end
prefs=ea_prefs;
dfoldsurf=[dfold,'fMRI',filesep,cname,filesep,'surf',filesep];
dfoldvol=[dfold,'fMRI',filesep,cname,filesep,'vol',filesep]; % expand to /vol subdir.

d=load([dfold,'fMRI',filesep,cname,filesep,'dataset_info.mat']);
dataset=d.dataset;
clear d;
if exist('outputmask','var')
    if ~isempty(outputmask)
        omask=ea_load_nii(outputmask);
        omaskidx=find(omask.img(:));
        [~,maskuseidx]=ismember(omaskidx,dataset.vol.outidx);
    else
        omaskidx=dataset.vol.outidx;
        maskuseidx=1:length(dataset.vol.outidx);
    end
else
    omaskidx=dataset.vol.outidx; % use all.
    maskuseidx=1:length(dataset.vol.outidx);
end

owasempty=0;
if ~exist('outputfolder','var')
    outputfolder=ea_getoutputfolder(sfile,ocname);
    owasempty=1;
else
    if isempty(outputfolder) % from shell wrapper.
        outputfolder=ea_getoutputfolder(sfile,ocname);
        owasempty=1;
    end
    if ~strcmp(outputfolder(end),filesep)
        outputfolder=[outputfolder,filesep];
    end
end

if strcmp(sfile{1}(end-2:end),'.gz')
    %gunzip(sfile)
    %sfile=sfile(1:end-3);
    usegzip=1;
else
    usegzip=0;
end

for s=1:size(sfile,1)
    if size(sfile(s,:),2)>1
        dealingwithsurface=1;
    else
        dealingwithsurface=0;
    end
    for lr=1:size(sfile(s,:),2)
        if exist(ea_niigz(sfile{s,lr}),'file')
            seed{s,lr}=ea_load_nii(ea_niigz(sfile{s,lr}));
        else
            if size(sfile(s,:),2)==1
                ea_error(['File ',ea_niigz(sfile{s,lr}),' does not exist.']);
            end
            switch lr
                case 1
                    sidec='l';
                case 2
                    sidec='r';
            end
            seed{s,lr}=dataset.surf.(sidec).space; % supply with empty space
            seed{s,lr}.fname='';
            seed{s,lr}.img(:)=0;
        end
        if ~isequal(seed{s,lr}.mat,dataset.vol.space.mat) && (~dealingwithsurface)
            oseedfname=seed{s,lr}.fname;

            try
                seed{s,lr}=ea_conformseedtofmri(dataset,seed{s,lr});
            catch
                keyboard
            end
            seed{s,lr}.fname=oseedfname; % restore original filename if even unneccessary at present.
        end

        [~,seedfn{s,lr}]=fileparts(sfile{s,lr});
        if dealingwithsurface
            sweights=seed{s,lr}.img(:);
        else
            sweights=seed{s,lr}.img(dataset.vol.outidx);
        end
        sweights(isnan(sweights))=0;
        sweights(isinf(sweights))=0; %

        sweights(abs(sweights)<0.0001)=0;
        sweights=double(sweights);

        try
            options=evalin('caller','options');
        end
        if exist('options','var')
            if strcmp(options.lcm.seeddef,'parcellation')
                sweights=round(sweights);
            end
        end
        % assure sum of sweights is 1
        %sweights(logical(sweights))=sweights(logical(sweights))/abs(sum(sweights(logical(sweights))));
        sweightmx=repmat(sweights,1,1);

        sweightidx{s,lr}=find(sweights);
        sweightidxmx{s,lr}=double(sweightmx(sweightidx{s,lr},:));
    end
end

numseed=s;
try
    options=evalin('caller','options');
end
if exist('options','var')
    if strcmp(options.lcm.seeddef,'parcellation') % expand seeds to define
        ea_error('Command not supported for parcellation as input.');
    end
end

disp([num2str(numseed),' seeds, command = ',cmd,'.']);

numSubUse = length(dataset.vol.subIDs);

if ~exist('subset','var') % use all subjects
    usesubjects = 1:numSubUse;
else
    for ds=1:length(dataset.subsets)
        if strcmp(subset,dataset.subsets(ds).name)
            usesubjects=dataset.subsets(ds).subs;
            break
        end
    end
    numSubUse = length(usesubjects);
end

numVoxUse = length(omaskidx);

% init vars:
for s=1:numseed-1
    fX{s}=nan(numVoxUse,numSubUse);
end

ea_dispercent(0,'Iterating through subjects');
for subj = 1:numSubUse % iterate across subjects
    mcfi = usesubjects(subj);
    howmanyruns=ea_cs_dethowmanyruns(dataset,mcfi);

    subIDVol = dataset.vol.subIDs{mcfi};

    targetix=sweightidx{1};
    clear stc
    thiscorr=zeros(numVoxUse,howmanyruns);

    for run=1:howmanyruns
        gmtcstruc = load([dfoldvol,subIDVol{run+1}]);
        gmtc = single(gmtcstruc.gmtc);
        for s=2:numseed
            stc(:,s-1)=mean(gmtc(sweightidx{s},:).*repmat(sweightidxmx{s},1,size(gmtc,2)));
        end

        % now we have all seeds, need to iterate across voxels of
        % target to get pmap values
        for s=1:size(stc,2)
            seedstc=stc(:,s);
            otherstc=stc;
            otherstc(:,s)=[];

            targtc=gmtc(targetix,:);
            thiscorr(targetix,run)=partialcorr(targtc',seedstc,otherstc);
        end
    end

    for s=1:size(stc,2)
        fX{s}(:,subj)=mean(thiscorr,2);
        if writeoutsinglefiles
            ccmap=dataset.vol.space;
            ccmap.fname=[outputfolder,seedfn{s},'_',subIDVol{1},'_pmap.nii'];
            ccmap.dt=[16 0];
            ccmap.img=single(ccmap.img);
            ccmap.img(omaskidx)=fX{s}(:,subj);
            spm_write_vol(ccmap,ccmap.img);
        end
    end
    ea_dispercent(subj/numSubUse);
end
ea_dispercent(1,'end');
seedfn(1)=[]; % delete first seed filename (which is target).

for s=1:size(seedfn,1) % subtract 1 in case of pmap command
    if owasempty
        outputfolder=ea_getoutputfolder(sfile(s),ocname);
    end
    % export mean
    M=ea_nanmean(fX{s}',1);
    mmap=dataset.vol.space;
    mmap.dt=[16,0];
    mmap.img(:)=0;
    mmap.img=single(mmap.img);
    mmap.img(omaskidx)=M;

    mmap.fname=[outputfolder,seedfn{s},'_func_',cmd,'_AvgR.nii'];
    ea_write_nii(mmap);
    if usegzip
        gzip(mmap.fname);
        delete(mmap.fname);
    end

    % export variance
    M=ea_nanvar(fX{s}');
    mmap=dataset.vol.space;
    mmap.dt=[16,0];
    mmap.img(:)=0;
    mmap.img=single(mmap.img);
    mmap.img(omaskidx)=M;

    mmap.fname=[outputfolder,seedfn{s},'_func_',cmd,'_VarR.nii'];
    ea_write_nii(mmap);
    if usegzip
        gzip(mmap.fname);
        delete(mmap.fname);
    end

    % fisher-transform:
    fX{s}=atanh(fX{s});

    % export fz-mean
    M=nanmean(fX{s}');
    mmap=dataset.vol.space;
    mmap.dt=[16,0];
    mmap.img(:)=0;
    mmap.img=single(mmap.img);
    mmap.img(omaskidx)=M;
    mmap.fname=[outputfolder,seedfn{s},'_func_',cmd,'_AvgR_Fz.nii'];
    spm_write_vol(mmap,mmap.img);
    if usegzip
        gzip(mmap.fname);
        delete(mmap.fname);
    end

    % export T
    [~,~,~,tstat]=ttest(fX{s}');
    tmap=dataset.vol.space;
    tmap.img(:)=0;
    tmap.dt=[16,0];
    tmap.img=single(tmap.img);

    tmap.img(omaskidx)=tstat.tstat;

    tmap.fname=[outputfolder,seedfn{s},'_func_',cmd,'_T.nii'];
    spm_write_vol(tmap,tmap.img);
    if usegzip
        gzip(tmap.fname);
        delete(tmap.fname);
    end
end

toc


function s=ea_conformseedtofmri(dataset,s)
td=tempdir;
dataset.vol.space.fname=[td,'tmpspace.nii'];
ea_write_nii(dataset.vol.space);
s.fname=[td,'tmpseed.nii'];
ea_write_nii(s);

ea_conformspaceto([td,'tmpspace.nii'],[td,'tmpseed.nii']);
s=ea_load_nii(s.fname);
delete([td,'tmpspace.nii']);
delete([td,'tmpseed.nii']);


function howmanyruns=ea_cs_dethowmanyruns(dataset,mcfi)
if strcmp(dataset.type,'fMRI_matrix')
    howmanyruns=1;
else
    howmanyruns=length(dataset.vol.subIDs{mcfi})-1;
end

function X=addone(X)
X=[ones(size(X,1),1),X];

function [mat,loaded]=ea_getmat(mat,loaded,idx,chunk,datadir)

rightmat=(idx-1)/chunk;
rightmat=floor(rightmat);
rightmat=rightmat*chunk;
if rightmat==loaded;
    return
end

load([datadir,num2str(rightmat),'.mat']);
loaded=rightmat;
