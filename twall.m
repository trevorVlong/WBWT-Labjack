    %
    %  Implementation of 2D tunnel-wall corrections, described in twc.pdf
    %  Consistent units must be used here
    %
function corrected2D = twall(uncorrected2D,walldata)

    walldata = mean(walldata,2)';
    tunnelq = mean(uncorrected2D.tunnelq);
    
    dq = -((walldata-walldata(12))/walldata(12))* tunnelq;
    qwall = dq;
    
    LSwall= flip([qwall(1:11),qwall(13:15)]);
    USwall =  flip(qwall(16:29));
    
    

    % max number of iterations and convergence tolerance
    itmax = 400;
    tol = 1.0e-5;

    % reference chord and span
    cref = 9.0 * 0.0254;
    bref = 24.0*0.0254;

    nu = 1.5e-5;
    rho = uncorrected2D.rho;

    %-----------------------------------------------
    % exit-jet speed, from tunnel total pressure referenced to ambient
    %   (replace with actual data)
    %Vout = 10.0;
    Vout = uncorrected2D.Vinf_measured;
    %-----------------------------------------------
    % made-up airfoil forces Fx,Fz for testing 
    %   (replace with actual data)

    %Fx = -1.2 * 0.5*rho*Vout^2*cref * 1.0;
    Fx = mean(uncorrected2D.Fx);
    %Fz =  6.0 * 0.5*rho*Vout^2*cref * 1.0;
    Fz = mean(uncorrected2D.Fz);
    %-----------------------------------------------
    % uncorrected reduced data
    cxu = Fx / (0.5*rho*Vout^2 * cref*bref);
    clu = Fz / (0.5*rho*Vout^2 * cref*bref);
    Reu = Vout*cref/nu;

    %-----------------------------------------------
    % number of taps on each wall (one panel per tap)
    Ntap = 14;

    % number of panels upstream and downstream of tap section, and stretching ratio
    Ninl = 20;
    Nout = 20;
    xrat = 1.10;
    %xrat = 1.15;
    %xrat = 1.20;

    xair = 0.0 * 0.0254;
    zair = 0.0 * 0.0254;

    % extent of pressure-tap section, including tap half-intervals at each end
    xinl = -9.0 * 0.0254;
    xout =  19.0 * 0.0254;

    % pressure tap spacing = panel length over tap section
    dxtap = (xout-xinl)/Ntap;

    % bottom and top wall locations
    zbot = -16.0 * 0.0254;
    ztop =  20.0 * 0.0254;
    %zbot = -18.0 * 0.0254;
    %ztop =  18.0 * 0.0254;

    % location where reference pressure and speed are defined
    %  (for uncorrected coefficients)
    xref = xout;
    zref = zair;

    %-----------------------------------------------------------------
    % panel nodes
    Npan = Ninl + Ntap + Nout;

    xpbot(1:Npan+1) = 0;
    xptop(1:Npan+1) = 0;

    % pressure-tap section panel nodes
    xpbot(Ninl+1:Ninl+Ntap+1) = xinl:dxtap:xout;
    xptop(Ninl+1:Ninl+Ntap+1) = xinl:dxtap:xout;

    % inlet panel nodes set using geometric stretching upstream
    for k=1:Ninl
      fk = (xrat^k - 1)/(xrat - 1);
      xpbot(Ninl+1-k) = xinl - fk*dxtap;
      xptop(Ninl+1-k) = xinl - fk*dxtap;
    end

    % outlet panel nodes set using geometric stretching downstream
    for k=1:Nout
      fk = (xrat^k - 1)/(xrat - 1);
      xpbot(Ninl+Ntap+1+k) = xout + fk*dxtap;
      xptop(Ninl+Ntap+1+k) = xout + fk*dxtap;
    end

    zpbot(1:Npan+1) = zbot;
    zptop(1:Npan+1) = ztop;

    %-----------------------------------------------------------------
    % control points at panel midpoint, offset vertically towards flow
    xcbot(1:Npan) = 0.5*(xpbot(1:Npan)+xpbot(2:Npan+1));
    zcbot(1:Npan) = 0.5*(zpbot(1:Npan)+zpbot(2:Npan+1)) + 0.001*dxtap;
    xctop(1:Npan) = 0.5*(xptop(1:Npan)+xptop(2:Npan+1));
    zctop(1:Npan) = 0.5*(zptop(1:Npan)+zptop(2:Npan+1)) - 0.001*dxtap;

    % extend first,last panels very far to approximate infinite sheet
    xpbot(1) = xpbot(1) - 1000.0*dxtap;
    xptop(1) = xptop(1) - 1000.0*dxtap;
    xpbot(Npan+1) = xpbot(Npan+1) + 1000.0*dxtap;
    xptop(Npan+1) = xptop(Npan+1) + 1000.0*dxtap;

    %-----------------------------------------------------------------
    % BC-type flags and specified velocities
    %  1: p specified (equivalent to specified u for small gauge pressures)
    %  2: w specified 
    % -1: dgam/dx=0 specified
    % -2: w specified (via i-1 .. i streamfunction difference)

    ibcbot(1:Npan) = 0;
    ibctop(1:Npan) = 0;

    pspbot(1:Npan) = 0.0;
    psptop(1:Npan) = 0.0;

    wspbot(1:Npan) = 0.0;
    wsptop(1:Npan) = 0.0;

    %-------------------------------------------------------
    % inlet: w = 0 specified (flat wall)
    ibcbot(1) = 2;
    ibctop(1) = 2;
    
    ibcbot(2:Ninl) = -2;
    ibctop(2:Ninl) = -2;

    wspbot(1:Ninl) = 0.0;
    wsptop(1:Ninl) = 0.0;

    %-------------------------------------------------------
    % tap section: pressures specified
    ibcbot(Ninl+1:Ninl+Ntap) = 1;
    ibctop(Ninl+1:Ninl+Ntap) = 1;

    %- - - - - - - - - -
    % set made-up  p_wall-p_atm  at taps for testing using static-pressure routine
    %  (replace with actual data)
    Lam = Fx/(rho*Vout);
    Gam = Fz/(rho*Vout);

    % values for pressures in pascals
    pspbot_est(Ninl+1:Ninl+Ntap) = ...
      pstat(rho,Vout,Lam,Gam,xcbot(Ninl+1:Ninl+Ntap),zcbot(Ninl+1:Ninl+Ntap));
  
    pspbot(Ninl+1:Ninl+Ntap) = ...
        USwall;

    psptop_est(Ninl+1:Ninl+Ntap) = ...
      pstat(rho,Vout,Lam,Gam,xctop(Ninl+1:Ninl+Ntap),zctop(Ninl+1:Ninl+Ntap));
    
    psptop(Ninl+1:Ninl+Ntap) = ...
        LSwall;
    
    pspbot(Ninl+1:Ninl+Ntap) = pspbot(Ninl+1:Ninl+Ntap) * 1.75;
    psptop(Ninl+1:Ninl+Ntap) = psptop(Ninl+1:Ninl+Ntap) * 1.75;

    %- - - - - - - - - -

    %-------------------------------------------------------
    % exit (jet): p = 0 specified
    ibcbot(Ninl+Ntap+1:Ninl+Ntap+Nout) = 1;
    ibctop(Ninl+Ntap+1:Ninl+Ntap+Nout) = 1;

    pspbot(Ninl+Ntap+1:Ninl+Ntap+Nout) = 0.0;
    psptop(Ninl+Ntap+1:Ninl+Ntap+Nout) = 0.0;

    % constant gamma at far end
    %ibcbot(Ninl+Ntap+Nout) = -1;
    %ibctop(Ninl+Ntap+Nout) = -1;

    %--------------------------------------------------------
    % override, for testing

    %ibcbot(2:Ninl) = 2;
    %ibctop(2:Ninl) = 2;

    % flat walls over tap section
    ibcbot(Ninl+1:Ninl+Ntap) = -2;
    ibctop(Ninl+1:Ninl+Ntap) = -2;

    % flat walls over exit
    %ibcbot(Ninl+Ntap+1:Ninl+Ntap+Nout) = -2;
    %ibctop(Ninl+Ntap+1:Ninl+Ntap+Nout) = -2;

    %-----------------------------------------------------------------
    % put top and bottom data into convenient single common arrays

    xc(1:Npan) = xcbot;
    zc(1:Npan) = zcbot;
    xc(Npan+1:Npan+Npan) = xctop;
    zc(Npan+1:Npan+Npan) = zctop;

    ibc(1:Npan) = ibcbot;
    psp(1:Npan) = pspbot;
    wsp(1:Npan) = wspbot;

    ibc(Npan+1:Npan+Npan) = ibctop;
    psp(Npan+1:Npan+Npan) = psptop;
    wsp(Npan+1:Npan+Npan) = wsptop;


    xp1(1:Npan) = xpbot(1:Npan);
    zp1(1:Npan) = zpbot(1:Npan);
    xp2(1:Npan) = xpbot(2:Npan+1);
    zp2(1:Npan) = zpbot(2:Npan+1);

    xp1(Npan+1:Npan+Npan) = xptop(1:Npan);
    zp1(Npan+1:Npan+Npan) = zptop(1:Npan);
    xp2(Npan+1:Npan+Npan) = xptop(2:Npan+1);
    zp2(Npan+1:Npan+Npan) = zptop(2:Npan+1);

    %-----------------------------------------------------------------
    % allocate matrices and vectors
    N = 2*Npan;

    ucgamma = zeros(N,N);
    wcgamma = zeros(N,N);
    psicgamma = zeros(N,N);

    A = zeros(N,N);
    R = zeros(N,1);

    %-----------------------------------------------------------------
    % control-point velocity and streamfunction AIC matrices ...

    % .. of airfoil source and vortex
    [ucLam wcLam phicLam psicLam] = source(xc(1:N),zc(1:N), xair,zair);
    [ucGam wcGam phicGam psicGam] = vortex(xc(1:N),zc(1:N), xair,zair);

    % .. of vortex panels
    for j = 1:N
      [ucj wcj phicj psicj] = vorpan(xc(1:N),zc(1:N), xp1(j),zp1(j), xp2(j),zp2(j));
      ucgamma(1:N,j) = ucj;
      wcgamma(1:N,j) = wcj;
      psicgamma(1:N,j) = psicj;
    end

    %=========================================================================
    % set equation matrix elements for each control point
    for i=1:N
      if(ibc(i) == 1)
    %  specified pressure, formulated as a specified u
       A(i,1:N) = ucgamma(i,1:N);
    %  R(i) = Vinf + uc(i) - sqrt(Vout^2 - 2*psp(i)/rho - wc(i)^2);

      elseif(ibc(i) == 2)
    %  specified w
       A(i,1:N) = wcgamma(i,1:N);
    %  R(i) = wc(i) - wsp(i);

      elseif(ibc(i) == -1)
    %  specified zero gamma difference between i, i-1
       A(i,i) = 1;
       A(i,i-1) = -1;
    %  R(i) = gamma(i) - gamma(i-1);

      elseif(ibc(i) == -2)
    %  specified zero psi difference between i, i-1
       A(i,1:N) = psicgamma(i,1:N) - psicgamma(i-1,1:N);
    %  R(i) = psic(i) - psic(i-1);

      else
       fprintf('Undefined BC flag ibc = %i \n', ibc(i));
       stop

      end
    end

    [Lmat,Umat] = lu(A);

    %=========================================================================
    % initial guess for airfoil singularities and panel strengths
    Lam = 0.5*Vout*cref*cxu;
    Gam = 0.5*Vout*cref*clu;
    gamma(1:N,1) = 0.0;

    %=========================================================================
    % iteration loop
    for iter = 1:itmax

    %----------------------------------------------------------------------
    % freestream speed for singularity model
    Vinf = Vout - 0.5*Lam/(ztop-zbot);

    %----------------------------------------------------------------------
    % perturbation velocities at airfoil, from panels only
    ueff = 0.0;
    weff = 0.0;

    for j = 1:N
      [u1 w1 phi1 psi1] = vorpan(xair,zair, xp1(j),zp1(j), xp2(j),zp2(j));
      ueff = ueff + u1*gamma(j);
      weff = weff + w1*gamma(j);
    end

    % effective freestream speed seen by airfoil
    Veff = sqrt((Vinf+ueff)^2 + weff^2);

    % alpha correction
    
    Dal = atan2( weff , Vinf+ueff );

    % corrected force coefficients
    ca = cos(Dal);
    sa = sin(Dal);
    cx = (cxu*ca + clu*sa)*Vout^2/Veff^2;
    cl = (clu*ca - cxu*sa)*Vout^2/Veff^2;

    % corrected Reynolds number
    Re = Reu*Veff/Vout;

    % updated airfoil singularities
    Lamold = Lam;
    Gamold = Gam;

    Lam = 0.5*Veff*cref * cx;
    Gam = 0.5*Veff*cref * cl;

    dLam = Lam - Lamold;
    dGam = Gam - Gamold;
    %----------------------------------------------------------------------

    % velocities and streamfunction at control points
    uc = (ucgamma*gamma)' + ucLam*Lam + ucGam*Gam; %'
    wc = (wcgamma*gamma)' + wcLam*Lam + wcGam*Gam; %'
    psic = (psicgamma*gamma)' + psicLam*Lam + psicGam*Gam; %'

    % set equation matrix and r.h.s. elements for each control point
    for i=1:N
      if(ibc(i) == 1)
    %  specified pressure, formulated as a specified u
    %  A(i,1:N) = ucgamma(i,1:N);
       R(i) = Vinf + uc(i) - sqrt(Vout^2 - 2*psp(i)/rho - wc(i)^2);

      elseif(ibc(i) == 2)
    %  specified w
    %  A(i,1:N) = wcgamma(i,1:N);
       R(i) = wc(i) - wsp(i);

      elseif(ibc(i) == -1)
    %  specified zero gamma difference between i, i-1
    %  A(i,i) = 1;
    %  A(i,i-1) = -1;
       R(i) = gamma(i) - gamma(i-1);

      elseif(ibc(i) == -2)
    %  specified zero psi difference between i, i-1
    %  A(i,1:N) = psicgamma(i,1:N) - psicgamma(i-1,1:N);
       R(i) = psic(i) - psic(i-1);

      else
       fprintf('Undefined BC flag ibc = %i \n', ibc(i));
       stop

      end
    end

    %for i=1:N
    % fprintf('%8.4f ',A(i,1:N))
    % fprintf('\n')
    %end

    % back-substitute -R vector to solve system for panel strength changes
    btmp = -real(Lmat\R);
    dgamma = Umat\btmp;

    dgmax = 0.0;
    for i=1:N
      if(abs(dgamma) > abs(dgmax))
       dgmax = dgamma(i);
      end
    end

%     fprintf('%4i: dgmax=%10.2e   Lam =%8.5f   Gam =%8.5f   Vinf/Vout =%7.4f   Veff/Vout =%7.4f \n', ...
%         iter, dgmax/Vout, Lam/Vout, Gam/Vout, Vinf/Vout, Veff/Vout);

    if(abs(dgmax) < tol*Vout || iter == itmax) 
     break
    end

    % update panel strengths
    %rlx = 1.0;
    %rlx = 0.7;
    rlx = 0.2;
    gamma = gamma + rlx*dgamma;

    end % of iteration loop
    %=========================================================================

%     fprintf('\n Veff/Vout =%7.4f   cl =%8.4f   cx =%8.4f   Dal =%7.3f  \n', ...
%         Veff/Vout, cl, cx, Dal*180/pi);

    pc = 0.5*rho*( Vout^2 - (Vinf+uc).^2 - wc.^2);
    cpc = pc / (0.5*rho*Vout^2);

    % set normalized top and bottom variables for plotting
    ubot(1:Npan) = uc(1:Npan)/Vout;
    wbot(1:Npan) = wc(1:Npan)/Vout;
    cpbot(1:Npan) = cpc(1:Npan);
    psibot(1:Npan) = psic(1:Npan)/(Vout*cref);
    gambot(1:Npan) = gamma(1:Npan)/Vout;

    utop(1:Npan) = uc(Npan+1:Npan+Npan)/Vout;
    wtop(1:Npan) = wc(Npan+1:Npan+Npan)/Vout;
    cptop(1:Npan) = cpc(Npan+1:Npan+Npan);
    psitop(1:Npan) = psic(Npan+1:Npan+Npan)/(Vout*cref);
    gamtop(1:Npan) = gamma(Npan+1:Npan+Npan)/Vout;


%     plot(xcbot/0.0254,ubot,'b*-',xctop/0.0254,utop,'r*-');
%     xlabel('x');
%     ylabel('u/V   (bot: blue   top: red)');
% 
%     figure;
% 
%     plot(xcbot/0.0254,wbot,'b*-',xctop/0.0254,wtop,'r*-');
%     xlabel('x');
%     ylabel('w/V   (bot: blue   top: red)');
% 
%     figure;
% 
%     plot(xcbot/0.0254,cpbot,'b*-',xctop/0.0254,cptop,'r*-');
%     xlabel('x');
%     ylabel('Cp   (bot: blue   top: red)');
% 
%     figure;
% 
%     plot(xcbot/0.0254,psibot,'b*-',xctop/0.0254,psitop,'r*-');
%     xlabel('x');
%     ylabel('psi/Vc    (bot: blue   top: red)');
% 
%     figure;
% 
%     plot(xcbot/0.0254,gambot,'b*-',xctop/0.0254,gamtop,'r*-');
%     xlabel('x');
%     ylabel('gamma/V    (bot: blue   top: red)');
% 
% 
%     drawnow
    corrected2D = table;   
    corrected2D.cl_average = cl;
    corrected2D.cx_average = cx;
    corrected2D.Vinf = Veff;
    corrected2D.correctionITER = iter;
    %X = [clu cxu cl cx];
    %disp(X);
             
end