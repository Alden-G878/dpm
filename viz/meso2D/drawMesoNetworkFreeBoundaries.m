%% Script to draw development without boundaries

clear;
close all;
clc;

% create file name
fstr = 'local/mesoHMin2D_data/mesoHMin2D_N64_n32_ca1.14_kb01e-3_be50_da0.02_dl5_P1e-4_h0.5_cL0_cB0_seed10.posctc';
% fstr = '~/Jamming/CellSim/dpm/pos.test';

% read in data
mesoData = readMesoNetworkCTCS2D(fstr);

% packing fraction (only take frames with phi > 0.25)
phi = mesoData.phi;
idx = phi > 0.395;
phi = phi(idx);

% number of frames
NFRAMES = sum(idx);

% sim info
NCELLS = mesoData.NCELLS;
nv = mesoData.nv(idx,:);
LList = mesoData.L(idx,:);
ctcList = mesoData.ctcs(idx,:);
x = mesoData.x(idx,:);
y = mesoData.y(idx,:);
r = mesoData.r(idx,:);
zc = mesoData.zc(idx,:);
zv = mesoData.zv(idx,:);
a0 = mesoData.a0(idx,:);
l0 = mesoData.l0(idx,:);
t0 = mesoData.t0(idx,:);
kb = mesoData.kb(idx,:);
phi0 = sum(a0,2)./(LList(:,1).*LList(:,2));

% get preferred shape
calA0 = zeros(NFRAMES,NCELLS);
p0 = zeros(NFRAMES,NCELLS);
for ff = 1:NFRAMES
    a0tmp = a0(ff,:);
    l0tmp = l0(ff,:);
    for cc = 1:NCELLS
        p0tmp = sum(l0tmp{cc});
        p0(ff,cc) = p0tmp;
        calA0(ff,cc) = p0tmp^2/(4.0*pi*a0tmp(cc));
    end
end

% particle shape data
p = mesoData.p(idx,:);
a = mesoData.a(idx,:);
calA = p.^2./(4.0*pi*a);

% stress data
S = mesoData.S(idx,:);
P = 0.5*(S(:,1) + S(:,2));

%% Draw cells

% information for ellipses
th = 0.0:0.01:(2.0*pi);
NTHE = length(th);
ex = cos(th);
ey = sin(th);

% show vertices or not
showverts = 0;

% color by shape or size
colorOpt = 0;

if colorOpt == 1
    % color by real shape
    NCLR = 100;
    calABins = linspace(0.999*min(calA(:)),1.001*max(calA(:)),NCLR+1);
    cellCLR = jet(NCLR);
elseif colorOpt == 2
    % color by preferred shape
    NCLR = 100;
    calA0Bins = linspace(0.999*min(calA0(:)),1.001*max(calA0(:)),NCLR+1);
    cellCLR = jet(NCLR);
else
    [nvUQ, ~, IC] = unique(nv);
    IC = reshape(IC,NFRAMES,NCELLS);
    NUQ = length(nvUQ);
    cellCLR = winter(NUQ);
end

% construct list of contacts
gijList = cell(NFRAMES,1);
for ff = 1:NFRAMES
    nvtmp = sum(nv(ff,:));
    ctctmp = ctcList{ff};
    gijtmp = zeros(nvtmp);
    gi = 1;
    ctchit = 1;
    for ii = 1:nvtmp
        for jj = (ii+1):nvtmp
            if gi == (ctctmp(ctchit)+1)
                gijtmp(ii,jj) = 1;
                gijtmp(jj,ii) = 1;
                ctchit = ctchit + 1;
                if ctchit > length(ctctmp)
                    break;
                end
            end
            gi = gi+1;
        end
        if ctchit > length(ctctmp)
            break;
        end
    end
    gijList{ff} = gijtmp;
end

% get cc contacts
cijList = cell(NFRAMES,1);
for ff = 1:NFRAMES
    gijtmp = gijList{ff};
    cijtmp = zeros(NCELLS);
    nvtmp = nv(ff,:);
    szList = [0 cumsum(nvtmp(1:end-1))] + 1;
    for nn = 1:NCELLS
        for mm = (nn+1):NCELLS
            ctcfound = 0;
            gi = szList(nn);
            for vi = 1:nvtmp(nn)
                gj = szList(mm);
                for vj = 1:nvtmp(mm)
                    if gijtmp(gi,gj) == 1 && ctcfound == 0
                        cijtmp(nn,mm) = 1;
                        cijtmp(mm,nn) = 1;
                        ctcfound = 1;
                    end
                    gj = gj + 1;
                end
                gi = gi + 1;
            end
        end
    end
    cijList{ff} = cijtmp;
end

% get frames to plot
if showverts == 0
    FSTART = 26;
    FSTEP = 1;
    if NFRAMES > 50
        FSTEP = 2;
    elseif NFRAMES > 150
        FSTEP = 10;
    end
%     FEND = NFRAMES;
    FEND = FSTART;
else
    FSTART = 2;
    FSTEP = 1;
    FEND = NFRAMES;
end

% make a movie
makeAMovie = 0;
ctccopy = 0;
if makeAMovie == 1
    moviestr = 'mesoHMin2D_N128_n32_ca1.14_kb01e-3_be50_da0.02_dl7_P1e-4_h0.5_cL0_cB0_seed12.mp4';
%     moviestr = 'mesoHMin2D_N64_n24_ca1.14_kb01e-3_be100_da0.05_dl0.1_P1e-8_h0.5_cL1_cB1_seed100.mp4';
    vobj = VideoWriter(moviestr,'MPEG-4');
    vobj.FrameRate = 15;
    open(vobj);
end

fnum = 1;
figure(fnum), clf, hold on, box on;
for ff = FSTART:FSTEP:FEND
    % reset figure for this frame
    figure(fnum), clf, hold on, box on;
    fprintf('printing frame ff = %d/%d, phi=%0.3g, phi0=%0.3g\n',ff,FEND,phi(ff),phi0(ff));
    
    % get geometric info
    xf = x(ff,:);
    yf = y(ff,:);
    rf = r(ff,:);
    zctmp = zc(ff,:);
    L = LList(ff,1);
    for nn = 1:NCELLS
        xtmp = xf{nn};
        ytmp = yf{nn};
        cx = mean(xtmp);
        cy = mean(ytmp);
        rx = xtmp - cx;
        ry = ytmp - cy;
        cx = mod(cx,L);
        cy = mod(cy,L);
        xtmp = cx + rx;
        ytmp = cy + ry;
        rtmp = rf{nn};
        nvtmp = nv(ff,nn);
        if colorOpt == 2
            cbin = calA0(ff,nn) > calA0Bins(1:end-1) & calA0(ff,nn) < calA0Bins(2:end);
            clr = cellCLR(cbin,:);
        elseif colorOpt == 1
            cbin = calA(ff,nn) > calABins(1:end-1) & calA(ff,nn) < calABins(2:end);
            clr = cellCLR(cbin,:);
        else
            clr = cellCLR(IC(ff,nn),:);
        end
        if showverts == 1
            for vv = 1:nvtmp
                rv = rtmp(vv);
                xplot = xtmp(vv) - rv;
                yplot = ytmp(vv) - rv;
                for xx = 0
                    for yy = 0
                        if nn > 0
                            rectangle('Position',[xplot + xx*L, yplot + yy*L, 2.0*rv, 2.0*rv],'Curvature',[1 1],'EdgeColor','k','FaceColor',clr,'LineWidth',1.5);
                        else
                            rectangle('Position',[xplot + xx*L, yplot + yy*L, 2.0*rv, 2.0*rv],'Curvature',[1 1],'EdgeColor','k','FaceColor','w');
                        end
                    end
                end
            end
        else
            rx = xtmp - cx;
            ry = ytmp - cy;
            rads = sqrt(rx.^2 + ry.^2);
            xtmp = xtmp + 0.8*rtmp.*(rx./rads);
            ytmp = ytmp + 0.8*rtmp.*(ry./rads);
            for xx = 0
                for yy = 0
                    vpos = [xtmp + xx*L, ytmp + yy*L];
                    finfo = [1:nvtmp 1];
                    patch('Faces',finfo,'vertices',vpos,'FaceColor',clr,'EdgeColor','k','Linewidth',1.5,'markersize',10);
                end
            end
        end
    end
    
%     % plot vv contacts
%     gijtmp = gijList{ff};
%     xa = cell2mat(xf');
%     ya = cell2mat(yf');
%     NVTOT = sum(nv(ff,:));
%     for gi = 1:NVTOT
%         xi = xa(gi);
%         yi = ya(gi);
%         for gj = (gi+1):NVTOT
%             if (gijtmp(gi,gj) == 1)
%                 dx = xa(gj) - xi;
%                 dx = dx - L*round(dx/L);
%                 dy = ya(gj) - yi;
%                 dy = dy - L*round(dy/L);
%                 for xx = ctccopy
%                     for yy = ctccopy
%                         plot([xi, xi + dx] + xx*L,[yi, yi + dy] + yy*L,'w-','linewidth',1.5);
%                     end
%                 end
%             end
%         end
%     end
        
    % plot box
    plot([0 L L 0 0], [0 0 L L 0], 'k-', 'linewidth', 1.5);
    axis equal;
    ax = gca;
    ax.XTick = [];
    ax.YTick = [];
    ax.XLim = [-0.25 1.25]*LList(end,1);
    ax.YLim = [-0.25 1.25]*LList(end,2);
    
    % if making a movie, save frame
    if makeAMovie == 1
        currframe = getframe(gcf);
        writeVideo(vobj,currframe);
    end
end


% close video object
if makeAMovie == 1
    close(vobj);
end



return;