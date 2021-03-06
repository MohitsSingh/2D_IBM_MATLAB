%-------------------------------------------------------------------------------------------------------------------%
%
% IB2d is an Immersed Boundary Code (IB) for solving fully coupled non-linear 
% 	fluid-structure interaction models. This version of the code is based off of
%	Peskin's Immersed Boundary Method Paper in Acta Numerica, 2002.
%
% Author: Nicholas A. Battista
% Email:  nick.battista@unc.edu
% Date Created: May 27th, 2015
% Institution: UNC-CH
%
% This code is capable of creating Lagrangian Structures using:
% 	1. Springs
% 	2. Beams (*torsional springs)
% 	3. Target Points
%	4. Muscle-Model (combined Force-Length-Velocity model, "HIll+(Length-Tension)")
%
% One is able to update those Lagrangian Structure parameters, e.g., spring constants, resting %%	lengths, etc
% 
% There are a number of built in Examples, mostly used for teaching purposes. 
% 
% If you would like us %to add a specific muscle model, please let Nick (nick.battista@unc.edu) know.
%
%--------------------------------------------------------------------------------------------------------------------%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: creates the RUBBERBAND-EXAMPLE geometry and prints associated input files
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Rubberband()

%
% Grid Parameters (MAKE SURE MATCHES IN input2d !!!)
%
Nx =  64;        % # of Eulerian Grid Pts. in x-Direction (MUST BE EVEN!!!)
Ny =  64;        % # of Eulerian Grid Pts. in y-Direction (MUST BE EVEN!!!)
Lx = 1.0;        % Length of Eulerian Grid in x-Direction
Ly = 1.0;        % Length of Eulerian Grid in y-Direction


% Immersed Structure Geometric / Dynamic Parameters %
N = 2*Nx;        % Number of Lagrangian Pts. (2x resolution of Eulerian grid)
ds = Lx/(2*Nx);  % Lagrangian Spacing
a = 0.4;         % Length of semi-major axis.
b = 0.2;         % Length of semi-minor axis.
struct_name = 'rubberband'; % Name for .vertex, .spring, etc files.


% Call function to construct geometry
[xLag,yLag,C] = give_Me_Immsersed_Boundary_Geometry(ds,N,a,b);


% Plot Geometry to test
plot(xLag,yLag,'r-'); hold on;
plot(xLag,yLag,'*'); hold on;
xlabel('x'); ylabel('y');
axis square;


% Prints .vertex file!
print_Lagrangian_Vertices(xLag,yLag,struct_name);


% Prints .spring file!
%k_Spring = 1e7;
%print_Lagrangian_Springs(xLag,yLag,k_Spring,ds_Rest,struct_name);


% Prints .beam file!
k_Beam = 1e7;
print_Lagrangian_Beams(xLag,yLag,k_Beam,C,struct_name);


% Prints .target file!
%k_Target = 1e7;
%print_Lagrangian_Target_Pts(xLag,k_Target,struct_name);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints VERTEX points to a file called rubberband.vertex
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Vertices(xLag,yLag,struct_name)

    N = length(xLag);

    vertex_fid = fopen([struct_name '.vertex'], 'w');

    fprintf(vertex_fid, '%d\n', N );

    %Loops over all Lagrangian Pts.
    for s = 1:N
        X_v = xLag(s);
        Y_v = yLag(s);
        fprintf(vertex_fid, '%1.16e %1.16e\n', X_v, Y_v);
    end

    fclose(vertex_fid); 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints Vertex points to a file called rubberband.vertex
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Target_Pts(xLag,k_Target,struct_name)

    N = length(xLag);

    target_fid = fopen([struct_name '.target'], 'w');

    fprintf(target_fid, '%d\n', N );

    %Loops over all Lagrangian Pts.
    for s = 1:N
        fprintf(target_fid, '%d %1.16e\n', s, k_Target);
    end

    fclose(target_fid); 
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints BEAM (Torsional Spring) points to a file called rubberband.beam
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Beams(xLag,yLag,k_Beam,C,struct_name)

    % k_Beam: beam stiffness
    % C: beam curvature
    
    N = length(xLag); % NOTE: Total number of beams = Number of Total Lag Pts. - 2

    beam_fid = fopen([struct_name '.beam'], 'w');

    v=1:2:N-1;
    
    fprintf(beam_fid, '%d\n', N );
    %fprintf(beam_fid, '%d\n', length(v) );

    %spring_force = kappa_spring*ds/(ds^2);

    %BEAMS BETWEEN VERTICES
    %for s = 1:2:N-1
    for s=1:N
            if s==1
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',N, s, s+1, k_Beam, C(s) );  
            elseif  s <= N-1         
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, s+1, k_Beam, C(s) );  
            else
                %Case s=N
                fprintf(beam_fid, '%d %d %d %1.16e %1.16e\n',s-1, s, 1,   k_Beam, C(s) );  
            end
    end
    fclose(beam_fid); 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: prints SPRING points to a file called rubberband.spring
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function print_Lagrangian_Springs(xLag,yLag,k_Spring,ds_Rest,struct_name)

    N = length(xLag);

    spring_fid = fopen([struct_name '.spring'], 'w');

    fprintf(spring_fid, '%d\n', N );

    %spring_force = kappa_spring*ds/(ds^2);

    %SPRINGS BETWEEN VERTICES
    for s = 1:N
            if s < N         
                fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, s+1, k_Spring, ds_Rest);  
            else
                %Case s=N
                fprintf(spring_fid, '%d %d %1.16e %1.16e\n', s, 1,   k_Spring, ds_Rest);  
            end
    end
    fclose(spring_fid); 
    
    

    

    
    

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: gives actually ELLIPTICAL piece
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [x,y,t] = compute_ELLIPTIC_Branch(ds,rmin,rmax)


%initiate
ct = 1;
t(1) = 0;
xN = rmin*cos(0);   x(ct) = xN;
yN = rmax*sin(0);   y(ct) = yN;

while t <= 2*pi-ds; 
    
    %update counter
    ct = ct+1;
    
    xP = x(ct-1);           % x-Prev
    yP = y(ct-1);           % y-Prev
    
    tN = t(ct-1);                 % previous angle
    tF = tN + pi/20;         % far guess
    tGuess = (tN + tF)/2;   % guess
    
    xN1 = rmin*cos(tGuess);   % x-guess 
    yN1 = rmax*sin(tGuess);   % y-guess
    err = ( ds - sqrt( (xN1-xP)^2 + (yN1-yP)^2 ) );
    
    while abs(err) > 1e-6
       
       if err > 0
          
          tN = tGuess;              % Update 'close' PT. [tN,tGuess,tF]
          tGuess = (tN+tF)/2;       % New Guess
          xN1 = rmin*cos(tGuess);   % x-guess 
          yN1 = rmax*sin(tGuess);   % y-guess          
          
       elseif err < 0
           
          tF = tGuess;             % Update FAR PT. [tN,tGuess,tF] 
          tGuess = (tF+tN)/2;     % New Guess
          xN1 = rmin*cos(tGuess);   % x-guess 
          yN1 = rmax*sin(tGuess);   % y-guess  
          
       end
        
       %compute error
       err = ( ds - sqrt( (xN1-xP)^2 + (yN1-yP)^2 ) );
        
    end

    %save values
    x(ct) = xN1;
    y(ct) = yN1;
    
    %update
    t(ct)=tGuess;
    
end

%x(ct+1) = rmin*cos(angEnd);  
%y(ct+1) = rmax*sin(angEnd);     
    
    
    
    
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: creates the Lagrangian structure geometry
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [xLag,yLag,C] = give_Me_Immsersed_Boundary_Geometry(ds,N,rmin,rmax)

% The immsersed structure is an ellipse %
[xLag,yLag,angs] = compute_ELLIPTIC_Branch(ds,rmin,rmax);
xLag = xLag + 0.5;
yLag = yLag + 0.5;

% COMPUTES CURAVTURE IF WANT TO STAY IN INITIAL CONFIGURATION
C = compute_Curvatures(ds,angs,rmin,rmax,xLag,yLag);

N = length(xLag);
r_eff = sqrt(rmin*rmax);
for i=1:N
    
    xLag2(i) = 0.5 + r_eff * cos( 2*pi/N*(i-1) );
    yLag2(i) = 0.5 + r_eff * sin( 2*pi/N*(i-1) );
    
end

% COMPUTES CURAVTURE IF WANT TO SETTLE INTO A CIRCLE
C = compute_Curvatures(ds,angs,rmin,rmax,xLag2,yLag2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% FUNCTION: computes "curvature" of ellipse
% 
% NOTE: not curvature in the traditional geometric sense, in the 'discrete'
% sense through cross product.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function C = compute_Curvatures(ds,angs,rmin,rmax,xLag,yLag)

%a-x component (rmin)
%b-y component (rmax)
%C = ab / ( sqrt( a^2*sin(t)^2 + b^2*cos(t)^2  )  )^3

N = length(xLag);
C = zeros( length(angs) );

%Note: -needs to be done same order as you print .beam file!
%      -THIS MAKES INITIAL BEAM CONFIGURATION THE DESIRED CURAVTURE!!
for i=1:N
   
   if i==1
   
        % Pts Xp -> Xq -> Xr (same as beam force calc.)
        Xp = xLag(N); Xq = xLag(i); Xr = xLag(i+1);
        Yp = yLag(N); Yq = yLag(i); Yr = yLag(i+1);
   
   elseif i<N
   
        % Pts Xp -> Xq -> Xr (same as beam force calc.)
        Xp = xLag(i-1); Xq = xLag(i); Xr = xLag(i+1);
        Yp = yLag(i-1); Yq = yLag(i); Yr = yLag(i+1);
       
   else
       
        % Pts Xp -> Xq -> Xr (same as beam force calc.)
        Xp = xLag(i-1); Xq = xLag(i); Xr = xLag(1);
        Yp = yLag(i-1); Yq = yLag(i); Yr = yLag(1);
        
   end
   C(i) = (Xr-Xq)*(Yq-Yp) - (Yr-Yq)*(Xq-Xp); %Cross product btwn vectors
   
   
end

