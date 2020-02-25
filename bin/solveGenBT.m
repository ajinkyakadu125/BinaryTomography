function [xD,hist] = solveGenBT(A,b,ug,options)
%solveBT A primal-dual algorithm to find a solution to
%
%   min_{x} 0.5*\|x - b\|_2^2 + p1*\|A'*x\|_1 + p2*sum(A'*x)
%
%  where p1 = (u1 - u0)/2 and p2 = (u1 + u0)/2
% Input:
%   A : a (tomography) matrix of size m x n
%   b : (tomographic) projection data vector of size m x 1
%   ug : greylevel vector (2 x 1 size)
%   options:
%       maxIter : maximum number of iterations (default: 1e3)
%       optTol  : tolerance level for optimality (default: 1e-6)
%       progTol : tolerance level for progress (default: 1e-6)
%       saveHist: an indicator for saving history (default:0)
%
% Output:
%   xD : solution (size n x 1)
%   hist - history containing values at each iteration
%       f : function value 0.5|x-b|_2^2
%       g : function value |A'*x|_1
%       cost : sum of two functions f and g
%       er : error value |x-xprev|_2 + |u - uprev|_2
% 
%
% Created by:
%   - Ajinkya Kadu, Utrecht University
%   Feb 18, 2020

maxIter = getoptions(options,'maxIter',1000);
optTol  = getoptions(options,'optTol',1e-6);
progTol = getoptions(options,'progTol',1e-6);
saveHist= getoptions(options,'saveHist',0);


[m,n] = size(A);

x = zeros(m,1);
u = zeros(n,1);


gamma = 0.95/normest(A);
%%

for k=1:maxIter
    
    % update primal variable (x)
    xp = x;
    x = proxf(xp-gamma*(A*u),b,gamma);
    
    % update dual variable (u)
    up = u;
    dx = xp-2*x;
    u  = proxgd(up-gamma*(A'*dx),gamma,ug(1),ug(2));
    
    
    % history
    hist.er(k)   = norm([x;u]-[xp;up]);
    hist.opt(k)  = norm(x - b + A*u);
    
    if saveHist
        Atx          = A'*x;
        hist.f(k)    = 0.5*norm(x-b)^2;
        hist.g(k)    = norm(Atx,1);
        hist.cost(k) = hist.f(k) + hist.g(k);
    end
    
    if (hist.opt(k) < optTol)
        fprintf('stopped at iteration %d \n',k);
        fprintf('Optimality: %d \n',hist.opt(k));
        fprintf('relative progress: %d \n',hist.er(k));
        break;
    end
    
    if (hist.er(k) < progTol)
        fprintf('stopped at iteration %d \n',k);
        fprintf('relative progress: %d \n',hist.er(k));
        fprintf('Optimality: %d \n',hist.opt(k));
        break;
    end
    
end

xD = u;

end

function [y] = proxf(x,b,gamma)
% proximal for f(x) = 0.5*|x - b|^2

y = (x + gamma*b)/(1+gamma);

end

function [y] = proxgd(x,gamma,u0,u1)
% proximal for dual of function |u0|*max(-x,0) + |u1|*max(x,0)

y = x - gamma*proxg(x/gamma,1/gamma,u0,u1);

end

function [y] = proxg(x,gamma,u0,u1)
% proximal for function g(x) = |u0|*max(-x,0) + |u1|*max(x,0)

t0= u0*gamma;
t1= u1*gamma;

y = max(0,x-t1) + min(0,x-t0);

end
