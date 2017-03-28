%% Rayleigh quotient iteration for an operator
% Nick Hale and Yuji Nakatsukasa, March 2017

%%
% (Chebfun example ode-eig/RayleighQuotient.m)

%% 1. Symmetric matrix
% The Rayleigh quotient iteration (RQI) is a well-known algorithm for computing
% an eigenpair of a matrix $A$ (symmetric or nonsymmetric). Using an approximate
% eigenvector $\tilde x$ (normalized s.t. $\|\tilde x\|_2=1$), it approximates
% an eigenvalue via $\tilde\lambda = \tilde x^\ast Ax$, and then updates the
% approximate eigenvector via one step
% of the shifted-and-inverted power method, $\tilde
% x:=(A-\tilde\lambda I)^{-1}\tilde x$, which is of course computed by solving a
% linear system. $\tilde x$ converges to an eigenvector, usually to the one 
% corresponding to the eigenvalue 
% $\tilde\lambda$ is closest to. The convergence of RQI is known to be
% asymptotically cubic when $A$ is symmetric [1, Sec. 4.6],
% and otherwise quadratic.

%%
% Here is an example showing cubic convergence for a random symmetric 
% $10\times 10$ matrix.
% (Note that we sacrifice some efficiency in computing $Au$
% in the residual computation 
% for the sake of clarity. This could easily be avoided.)

rng(10)
tol = 1e-10;
n = 10;
A = randn(n); A = A'+A;                      % symmetric matrix
I = eye(size(A));                            % identity matrix

% Initial guesses:
disp('lam:')
lam = A(end,end); disp(lam)                  % seek eigenvalue near lam
u = rand(n,1);  u = u/norm(u);               % random guess
res = norm(A*u - lam*u)/norm(A*u);           % initial residual

% Rayleigh quotient iteration:
while ( res(end) > tol )
    u = (A - lam*I)\u; u = u/norm(u);        % core RQI
    lam = u'*A*u; disp(lam)                  % update Rayleigh quotient
    res = [res; norm(A*u-lam*u)/norm(A*u)];  % store residual
end
res

%% 2. Nonsymmetric matrix
% Next let's try a nonsymmetric matrix. The convergence becomes quadratic. 

A = randn(n);                                 % nonsymmetric matrix
% Initial guesses:
disp('lam:')
lam = A(end,end); disp(lam)                   % seek eigenvalue near lam
u = rand(n,1)+1i*randn(n,1); u = u/norm(u);   % random guess (eigval can be complex)
res2 = norm(A*u - lam*u)/norm(A*u);           % initial residual

% Rayleigh quotient iteration:
while ( res2(end) > tol )
    u = (A - lam*I)\u; u = u/norm(u);         % core RQI
    lam = u'*A*u; disp(lam)                   % update Rayleigh quotient
    res2 = [res2; norm(A*u-lam*u)/norm(A*u)]; % store residual
end
res2

%%
% We can recover the cubic convergence by using the (conjugate) transpose
% and running a two-sided Rayleigh quotient iteration. Note that the
% algorithm is equivalent to RQI when $A$ is symmetric. 

A = randn(n);                                 % nonsymmetric matrix
% Initial guesses:
disp('lam:')
lam = A(end,end); disp(lam)                   % seek eigenvalue near lam
u = rand(n,1)+1i*randn(n,1);  u = u/norm(u);  % random guess for right ev
v = rand(n,1);  v = v/norm(v);                % random guess for left ev
res3 = norm(A*u - lam*u)/norm(A*u);           % initial residual

% two-sided Rayleigh quotient iteration: 
while ( res3(end) > tol )
    u = (A - lam*I)\u; u = u/norm(u);         % core RQI
    v = (A - lam*I)'\ v; v = v/norm(v);       % core RQI for left eigvec    
    lam = (v'*A*u)/(v'*u); disp(lam)          % update Rayleigh quotient
    res3 = [res3; norm(A*u-lam*u)/norm(A*u)]; % store residual
end
res3

% plot convergence rates
CO = 'color';
semilogy(res, 'b-o'), hold on
text(length(res) + .1, res(end), 'symm', CO, 'b')
semilogy(res2, 'r--x' )
text(length(res2) - .9, res2(end-1), 'nonsymm', CO, 'r')
semilogy(res3, 'm--^' )
text(length(res3) - .9, res3(end-1), 'nonsymm two-sided', CO, 'r')
xlabel('iteration'), ylabel('residual')
grid on, hold off

%% 3. Selfadjoint linear operator
% Now we explore the use of RQI for a linear operator, represented by a chebop.
% Let us consider the selfadjoint operator $Au = -u''$ with selfadjoint
% Dirichlet boundary conditions $u(-\pi/2) = u(\pi/2) = 0$. 
% As an initial guess we use a random function generated by the
% randnfun command. 
% Notice that the code for the RQI is almost identical to the matrix
% case above!

dom = [-pi/2, pi/2];
A = chebop(@(u) -diff(u, 2), dom, 0);       % self-adjoint operator
Alam = @(lam) chebop(@(u) ...               % A - lam*I
   -diff(u, 2)-lam*u, dom, 0);

% Initial guesses:
disp('lam:')
lam = 3.8; disp(lam)                        % seek eigenvalue near lam 
u = randnfun(.1, 1, dom);  u = u/norm(u);   % random guess

res = norm(Alam(lam)*u)/norm(A*u);          % initial residual

% Rayleigh quotient iteration:
while ( res(end) > tol )
    u = Alam(lam)\u; u = u/norm(u);         % core RQI
    lam = u'*A*u; disp(lam)                 % update Rayleigh quotient
    res = [res; norm(Alam(lam)*u)/ ...
       norm(A*u)+norm(A.bc(u))];            % store residual
end

%%
% From the residual output, we can guess that the convergence is cubic
% (it is actually too fast to verify). 

res

%% 5. Non-selfadjoint linear operator
% Now consider the non-selfadjoint operator
% $Au = -u'' + u' + u$, again with zero
% Dirichlet boundary conditions:

dom = [-pi/2, pi/2];
A = chebop(@(u) -diff(u,2) + diff(u) + u, dom, 0);
Alam = @(lam) chebop(@(u) ...                         % A - lam*I
   -diff(u,2) + diff(u) + u -lam*u, dom, 0);

% Initial guesses:
disp('lam:')
lam = 1; disp(lam)
u = randnfun(.1, 1, dom); u = u/norm(u);
res2 = norm(Alam(lam)*u) / norm(A*u);

% Rayleigh quotient iteration:
while ( res2(end) > tol)
    u = Alam(lam)\u; u = u/norm(u);   
    lam = u'*A*u; disp(lam)
    res2 = [res2; norm(Alam(lam)*u)/norm(A*u) + norm(A.bc(u))];
end

%%
% From the residual output, we can see that here the convergence is quadratic:

res2

%%
% As before, let's try to improve the convergence to cubic.
% This involves the adjoint. 

% Initial guesses:
disp('lam:')
lam = 1; disp(lam)
u = randnfun(.1, 1, dom); u = u/norm(u);
v = randnfun(.1, 1, dom); v = v/norm(v);
res3 = norm(Alam(lam)*u) / norm(A*u);
At = adjoint(A);
Atlam = @(lam) chebop(@(u) -diff(u,2)...   % A - lam*I
       - diff(u) + u -lam*u, dom, 0);

% Rayleigh quotient iteration:
while ( res3(end) > tol)
    u = Alam(lam)\u; u = u/norm(u);        % RQI
    v = Atlam(lam)\v; v = v/norm(v);       % adjoint RQI
    lam = v'*(A*u)/(v'*u); disp(lam)       % two-sided approximation
    res3 = [res3; norm(Alam(lam)*u)/ ...
       norm(A*u) + norm(A.bc(u))];
end

res3

%% 5. Convergence rates
% RQI appears to have computed eigenpairs for both operators, selfadjoint and
% non-selfadjoint. Now let's examine the convergence rates by plotting the
% residual convergence.

semilogy(res, 'b-o'), hold on
text(length(res) + .1, res(end), 'selfadj', CO, 'b')
semilogy(res2, 'r--x' )
text(length(res2) - .9, res2(end-1), 'non-selfadj', CO, 'r')   
semilogy(res3, 'm--^' )
text(length(res3) - .9, res3(end-1), 'non-selfadj two-sided', CO, 'm')   
xlabel('iteration'), ylabel('residual')
grid on

%% 6. References
%
% 1. B. N. Parlett, _The Symmetric Eigenvalue Problem_, SIAM, 1996.