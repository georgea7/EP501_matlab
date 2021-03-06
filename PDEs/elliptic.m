%% Need some linear algebra tools in order to solve elliptic equations
% del^2 Phi = 0 
% 
% encoded as a matrix system of the form:
% M * Phi = b
%
addpath ../linear_algebra;


%% Define a 2D grid in x,y for a test problem
lx=25;                 % grid size in x
ly=25;                 % size of grid in y-direction
N=lx*ly;               % total number of grid points
a=1;
b=a;                   % use a square region for a test problem
x=linspace(0,a,lx);
y=linspace(0,b,ly);
dx=x(2)-x(1);          % constant grid spacing
dy=y(2)-y(1);          % ditto
[X,Y]=meshgrid(x,y);


%% Define Dirichlet boundary conditions for the test problem:
f1=zeros(lx,1);    % bottom boundary condition, y=0
f2=sin(2*pi*x);    % top, y=b
g1=zeros(1,ly);    % left, x=0
g2=zeros(1,ly);    % right, x=a
%b=zeros(N,1);      % inhomogeneous terms
b=32*exp(-(X-0.5).^2/(0.25)^2).*exp(-(Y-0.5).^2/(0.1)^2);
b=b(:);


%% Setup of matrix for solving FDEs system size is NxN=lx*ly x lx*ly
M=zeros(N,N);
for j=1:ly
    for i=1:lx
        k=(j-1)*lx+i;
        if(j==1)      %min y boundary
            M(k,k)=1;
            
            %RHS of matrix system
            b(k)=f1(i);
        elseif(j==ly) %max y boundary 
            M(k,k)=1;
            
            %RHS
            b(k)=f2(i);            
        elseif(i==1)    %min x boundary
            M(k,k)=1;
            
            %RHS
            b(k)=g1(j);           
        elseif(i==lx)   %max x boundary
            M(k,k)=1;
            
            %RHS
            b(k)=g2(j);            
        else
          M(k,k-lx)=1/dy^2;    % alphak
          M(k,k-1)=1/dx^2;     % betak
          M(k,k)=-2/dx^2-2/dy^2;   %gammak
          M(k,k+1)=1/dx^2;         %deltak
          M(k,k+lx)=1/dy^2;        %epsilonk
          
          %RHS
          %b(k)=0;
        end %if
    end %for
end %for


%% Solution with the built-in Matlab matrix solver
disp('Solve time for backslash:  ');
tic
Phimatlab=M\b;
Phimatlab=reshape(Phimatlab,[lx,ly])';
toc

figure;
subplot(1,4,1);
imagesc(x,y,Phimatlab);
axis xy;
c=colorbar;
xlabel('x');
ylabel('y');
title('Matlab Solution');
ylabel(c,'Voltage (V)');
set(gca,'FontSize',20);


%% Execute of solution for our matrix system with self-coded solver from repo (direct, Gaussian elim.)
verbose=false;
disp('Solve time for repo Gauss elim:  ');
tic
[Mmod,ord]=Gauss_elim(M,b,verbose);
PhiGauss=backsub(Mmod(ord,:));
PhiGauss=reshape(PhiGauss,[lx,ly])';
toc

subplot(1,4,2);
imagesc(x,y,PhiGauss);
axis xy;
c=colorbar;
xlabel('x');
ylabel('y');
title('Gauss-Elim Solution');
ylabel(c,'Voltage (V)');
set(gca,'FontSize',20);


%% Solution with Jacobi iterative solver from repo
verbose=false;  
tol=1e-1;
Phi0=zeros(N,1);
disp('Solve time for repo Jacobi iter:  ');
tic
[PhiJacobi,nit]=Jacobi(Phi0,-1*M,-1*b,tol,verbose);
PhiJacobi=reshape(PhiJacobi,[lx,ly])';
toc

subplot(1,4,3);
imagesc(x,y,PhiJacobi);
axis xy;
c=colorbar;
xlabel('x');
ylabel('y');
title('Jacobi Iterations Solution');
ylabel(c,'Voltage (V)');
set(gca,'FontSize',20);


%% Check performace when using sparse storage
Ms=sparse(M);     %"typecast" matrix into sparse storage...
disp('Solve time for sparse backslash:  ');
tic
Phismatlab=Ms\b;
Phismatlab=reshape(Phismatlab,[lx,ly])';
toc


%% Compute and plot the analytical solution (see ./test_problems/ for derivation)
Phiexact=sinh(2*pi*Y)./sinh(2*pi).*sin(2*pi*X);

subplot(1,4,4);
imagesc(x,y,Phiexact);
axis xy;
c=colorbar;
xlabel('x');
ylabel('y');
title('Exact Solution');
ylabel(c,'Voltage (V)');
set(gca,'FontSize',20);


%% Reset paths when we are done (for consistency, cleanliness)
rmpath ../linear_algebra;

