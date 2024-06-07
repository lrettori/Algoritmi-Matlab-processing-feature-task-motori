% Funzione per il confronto della matrice generata dalla funzione Matlab
% filtfilt per il calcolo di zi (A_vers1) e la versione A_vers2 scritta per
% implementazione in C#

order = 10;
nFilt = order + 1;

a1 = randn(nFilt,1);

A_vers2 = zeros(nFilt - 1);

for ii = 1 : nFilt-1
    for jj = 1 : nFilt-1
        
        if jj == 1
            if ii == 1
                A_vers2(ii,jj) = 1 + a1(2);
            else
                A_vers2(ii,jj) = a1(ii+1);
            end
        elseif ii == jj
            A_vers2(ii,jj) = 1;
        elseif jj == ii + 1
            A_vers2(ii,jj) = -1;
        else
            A_vers2(ii,jj) = 0;
        end
    end
end

A_vers1 = (eye(nFilt-1) - [-a1(2:nFilt,1), [eye(nFilt-2); zeros(1,nFilt-2)]]);









err = sum(sum(abs(A_vers1 - A_vers2)))