function waves2mda(animal,rawdatadir,day,tet,varargin)

% Mari Sosa, 2017

% Example inputs: 
% rawdatadir = '/opt/data40/mari/EliotData/'; - parent dir where waves are kept, must end in /
% animal = 'eliot'; - must be lowercase
% day = 12;
% tet = 1;
applytimefilter = 0; %default

if (~isempty(varargin))
    assign(varargin{:});
end

% load waves and timestamps
cd(strcat(rawdatadir,animal,num2str(day,'%02d'),'/',num2str(tet,'%02d'),'-000'));
matfile = strcat(animal,num2str(day,'%02d'),'-',num2str(tet,'%02d'),'.mat');
load(matfile);

% swap rows and columns, so rows are channels and columns are clips
tmpwaves = permute(waves,[2,1,3]);
clear waves
[peaks,i] = max(tmpwaves,[],2); % i is the column index of the peak of each channel
[maxpeak,j] =max(peaks,[],1); % j is the row index of the peak across channel peaks

% use j to index i, find the index of the peak of each waveform across channels
j = reshape(j,1,size(j,3));
i = reshape(i,4,size(i,3));
peak_inds =  zeros(1,size(i,2));
for q = 1:size(i,2)
    peak_inds(q) = i(j(q),q);
end

% if specified, apply epoch timefilter to peak_inds and tmpwaves
% epochs will remain concatenated!
if applytimefilter
    load(sprintf('%s%s%02d/times.mat',rawdatadir,animal,day))
    timestamps = double(timestamps);
    logic = logical(isExcluded(timestamps,ranges(2:end,:))); % lists as 1s everything within the time ranges
    peak_inds = peak_inds(logic);
    tmpwaves = tmpwaves(:,:,logic);
end

% now reshape to create a buffer between the clips
raw =reshape(cat(2,tmpwaves,zeros(size(tmpwaves))),4,2*40*size(tmpwaves,3));
event_times=peak_inds+(0:size(tmpwaves,3)-1)*2*40;
event_times = int32(event_times);

%write mda files
cd(strcat(rawdatadir,animal,num2str(day,'%02d')))
if ~exist(sprintf('%s%02d.mda',animal,day),'dir')
    mkdir(sprintf('%s%02d.mda',animal,day))
end
cd(sprintf('%s%02d.mda',animal,day))

writemda(event_times,sprintf('event_times.nt%02d.mda',tet),'int32');
writemda(raw,sprintf('raw.nt%02d.mda',tet),'int16');





 
