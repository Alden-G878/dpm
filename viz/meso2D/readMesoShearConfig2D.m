
function dpmConfigData = readMesoShearConfig2D(fstr)
%% FUNCTION to read in DPM config data given file string
% Specifically for mesoNetwork2D data

% print info to console
finfo = dir(fstr);
fprintf('-- Reading in %s\n',finfo.name);
fprintf('-- File size = %f MB\n',finfo.bytes/1e6);

% open file stream
fid = fopen(fstr);

% read in sim details from first frame
NCELLS      = textscan(fid,'NUMCL %f',1,'HeaderLines',1);
NCELLS      = NCELLS{1};
phitmp      = textscan(fid,'PACKF %f',1);
fline       = fgetl(fid);
gammatmp    = textscan(fid,'GAMMA %f',1);
fline       = fgetl(fid);
Ltmp        = textscan(fid,'BOXSZ %f %f',1);
fline       = fgetl(fid);
Stmp        = textscan(fid,'STRSS %f %f %f',1);

% cells to save 
NFRAMES = 1e6;

phi     = zeros(NFRAMES,1);
gamma   = zeros(NFRAMES,1);
L       = zeros(NFRAMES,2);
S       = zeros(NFRAMES,3);

nv      = zeros(NFRAMES,NCELLS);
zc      = zeros(NFRAMES,NCELLS);
a0      = zeros(NFRAMES,NCELLS);
a       = zeros(NFRAMES,NCELLS);
p       = zeros(NFRAMES,NCELLS);

x       = cell(NFRAMES,NCELLS);
y       = cell(NFRAMES,NCELLS);
r       = cell(NFRAMES,NCELLS);
l0      = cell(NFRAMES,NCELLS);
t0      = cell(NFRAMES,NCELLS);
kb      = cell(NFRAMES,NCELLS);
zv      = cell(NFRAMES,NCELLS);


% number of frames found
nf = 1;

% loop over frames, read in data
while ~feof(fid)
    % get packing fraction
    phi(nf) = phitmp{1};
    
    % get shear strain
    gamma(nf) = gammatmp{1};
    
    % get box length
    L(nf,1) = Ltmp{1};
    L(nf,2) = Ltmp{2};
    
    % get stress info
    S(nf,1) = Stmp{1};
    S(nf,2) = Stmp{2};
    S(nf,3) = Stmp{3}; 
    
    % get info about deformable particle
    for nn = 1:NCELLS
        % get cell pos and asphericity
        cInfoTmp = textscan(fid,'CINFO %f %f %f %f %f',1);   
        fline = fgetl(fid);     % goes to next line in file

        NVTMP = cInfoTmp{1};
        nv(nf,nn) = NVTMP;
        zc(nf,nn) = cInfoTmp{2};
        a0(nf,nn) = cInfoTmp{3};
        a(nf,nn) = cInfoTmp{4};
        p(nf,nn) = cInfoTmp{5};
        
        % get vertex positions
        vInfoTmp = textscan(fid,'VINFO %*f %*f %f %f %f %f %f %f %f',NVTMP); 
        fline = fgetl(fid);     % goes to next line in file

        % parse data
        x{nf,nn} = vInfoTmp{1};
        y{nf,nn} = vInfoTmp{2};
        r{nf,nn} = vInfoTmp{3};
        l0{nf,nn} = vInfoTmp{4};
        t0{nf,nn} = vInfoTmp{5};
        kb{nf,nn} = vInfoTmp{6};
        zv{nf,nn} = vInfoTmp{7};
    end
    
    % increment frame count
    nf = nf + 1;
    
    % get ENDFR string, check that read is correct
    fline = fgetl(fid);
    endFrameStr = sscanf(fline,'%s');
    
    if ~strcmp(endFrameStr,'ENDFR')
        error('Miscounted number of particles in .pos file, ending data read in');
    end
    
    % start new frame information
    if ~feof(fid)
        % get NEWFR line
        fline       = fgetl(fid);
        newFrameStr = sscanf(fline,'%s %*s');
        if ~strcmp(newFrameStr,'NEWFR')
            error('NEWFR not encountered when expected when heading to new frame...check line counting. ending.');
        end
        
        % read in sim details from first frame
        NCELLStmp       = textscan(fid,'NUMCL %f');
        
        % read in packing fraction
        phitmp          = textscan(fid,'PACKF %f',1);                   
        fline = fgetl(fid);
        
        % read in shear strain
        gammatmp        = textscan(fid,'GAMMA %f',1);
        fline           = fgetl(fid);
        
        % update box size
        Ltmp            = textscan(fid,'BOXSZ %f %f',1);
        fline = fgetl(fid);
        
        % get new stress info
        Stmp            = textscan(fid,'STRSS %f %f %f',1);
        fline = fgetl(fid);
    end
end

% delete extra information
if (nf < NFRAMES)
    NFRAMES = nf-1;
    phi(nf:end) = [];
    gamma(nf:end) = [];
    L(nf:end,:) = [];
    S(nf:end,:) = [];
    
    nv(nf:end,:) = [];
    zc(nf:end,:) = [];
    a0(nf:end,:) = [];
    a(nf:end,:) = [];
    p(nf:end,:) = [];
    
    x(nf:end,:) = [];
    y(nf:end,:) = [];
    r(nf:end,:) = [];
    l0(nf:end,:) = [];
    t0(nf:end,:) = [];
    kb(nf:end,:) = [];
    zv(nf:end,:) = [];
end

% close position file
fclose(fid);

% store cell pos data into struct
dpmConfigData               = struct('NFRAMES',NFRAMES,'NCELLS',NCELLS);
dpmConfigData.phi           = phi;
dpmConfigData.gamma         = gamma;
dpmConfigData.L             = L;
dpmConfigData.S             = S;

dpmConfigData.nv            = nv;
dpmConfigData.zc            = zc;
dpmConfigData.a0            = a0;
dpmConfigData.a             = a;
dpmConfigData.p             = p;

dpmConfigData.x             = x;
dpmConfigData.y             = y;
dpmConfigData.r             = r;
dpmConfigData.l0            = l0;
dpmConfigData.t0            = t0;
dpmConfigData.kb            = kb;
dpmConfigData.zv            = zv;

end