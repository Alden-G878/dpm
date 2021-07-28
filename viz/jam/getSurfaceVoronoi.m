function [voroAreas, voroCalA] = getSurfaceVoronoi(xpos,ypos,nv,L)
%% Get Voronoi diagram from Delaunay triangulation

% number of particles
NCELLS = length(nv);

% all vertices + interpolated points
NINTERP = 15;
NVTOT = (NINTERP+1)*sum(nv);

% get vertices in global coordinates
gx = zeros(9*NVTOT,1);
gy = zeros(9*NVTOT,1);
ci = zeros(NVTOT,1);
gi = 1;
for nn = 1:NCELLS
    ip1 = [2:nv(nn) 1];
    xtmp = xpos{nn};
    ytmp = ypos{nn};
    for vv = 1:nv(nn)
        % add main point
        gx(gi) = xtmp(vv);
        gy(gi) = ytmp(vv);
        ci(gi) = nn;
        
        if NINTERP == 0
            gi = gi + 1;
        else
            % get segment to next
            lx = xtmp(ip1(vv)) - xtmp(vv);
            ly = ytmp(ip1(vv)) - ytmp(vv);
            l = sqrt(lx^2 + ly^2);
            del = l/(NINTERP+1);
            ux = lx/l;
            uy = ly/l;
            gi = gi + 1;
            for ii = 1:NINTERP
                gx(gi) = gx(gi-1) + del*ux;
                gy(gi) = gy(gi-1) + del*uy;
                ci(gi) = nn;
                gi = gi + 1;
            end
        end
    end
end

% also add periodic boundaries
blk = 1;
for xx = -1:1
    for yy = -1:1
       if (xx == 0 && yy == 0)
           continue;
       end
       
       % indices
       i0 = NVTOT*blk + 1;
       i1 = NVTOT*(blk + 1);
       
       % add
       gx(i0:i1) = gx(1:NVTOT) + xx*L;
       gy(i0:i1) = gy(1:NVTOT) + yy*L;
       
       % update block
       blk = blk + 1;
    end
end

% make delaunay
DT = delaunayTriangulation(gx,gy);

% voronoi diagram
[V,e] = voronoiDiagram(DT);

voroAreas = zeros(NCELLS,1);
svoroEdgeInfo = cell(NCELLS,1);
for vv = 1:NVTOT
    vvi = e{vv};
    vinfo = V(vvi,:);
    
    % add to area
    atmp = polyarea(vinfo(:,1),vinfo(:,2));
    voroAreas(ci(vv)) = atmp + voroAreas(ci(vv));
    
    % label all vertices as bndry, remove by checking interior edges
    NVCE = length(vvi);
    onbound = true(NVCE,1);
    civ = ci(vv);
    
    % find exterior surface by checking neighbors    
    vp1 = [vvi(2:end) vvi(1)];
    for ee = 1:NVCE
        % get pairs of vertices on edge
        ve1 = vvi(ee);
        ve2 = vp1(ee);
        
        % loop over other voronoi cells in this particle
        vint = find(ci == civ);
        NVINT = length(vint);
        for vvv = 1:NVINT
            if vint(vvv) == vv
                continue;
            end
            vvj = e{vint(vvv)};
            if sum(ve1 == vvj) == 1 && sum(ve2 == vvj) == 1
                onbound(ee) = false;
                break;
            end
        end
    end
    
    % add to master list
    for ee = 1:NVCE
        if onbound(ee)
            ve1 = vvi(ee);
            ve2 = vp1(ee);
            
            % add to face list
            svoroEdgeInfo{ci(vv)} = [svoroEdgeInfo{ci(vv)}; ve1, ve2];
        end
    end
end

% clean face list
svoroFaceList = cell(NCELLS,1);
for cc = 1:NCELLS
    % face list
    etmp = svoroEdgeInfo{cc};
    NVE = size(etmp,1);
    
    % construct face list
    ftmp = zeros(NVE,1);
    ftmp(1) = etmp(1,1);
    ftmp(2) = etmp(1,2);
    curr = 1;
    for ee = 2:NVE
        nxtind = etmp(curr,2) == etmp(:,1);
        ftmp(ee) = etmp(nxtind,1);
        curr = find(nxtind);
    end
    
    % save 
    svoroFaceList{cc} = ftmp;
end

% get calA for voronoi cells
voroCalA = zeros(NCELLS,1);
for cc = 1:NCELLS
    % get data for cell
    ftmp = svoroFaceList{cc};
    vatmp = voroAreas(cc);
    lx = V([ftmp(2:end); ftmp(1)],1) - V(ftmp,1);
    ly = V([ftmp(2:end); ftmp(1)],2) - V(ftmp,2);
    l = sqrt(lx.^2  + ly.^2);
    vptmp = sum(l);
    
    % compute shape parameter
    voroCalA(cc) = vptmp^2/(4.0*pi*vatmp);
end


end