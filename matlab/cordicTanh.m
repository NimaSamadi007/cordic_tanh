clc
clear

% look up table:
iteration = 13;
W = 16;
F = 12; 
z0 = fi(5.281, 1, W, F); % input value
hex(z0) % hex repr of input - for verilog
ROM = zeros(1, iteration); % tanh^(-1) values - also used in verilog
for i=1:iteration
    ROM(i) = fi(atanh(2^(-i)), 1, W, F); 
end

if (z0 >= 4) % greater than 4
    val = fi(1, 1, W, F);
elseif (z0 <= -4) % less than -4
    val = fi(-1, 1, W, F);
else % valid range
    val = cordicCal(z0, W, F, iteration, ROM);
end
disp("tanh CORDIC: " + num2str(hex(val)) + ", " + num2str(val)); % display value

function z = cordicCal(z0, W, F, iteration, ROM) % tanh caluculation
    % fixed point conversion
    xi = fi(1, 1, W, F); 
    yi = fi(0, 1, W, F);
    zi = z0;

    for i = 1:2*iteration % double iteration
        if(zi < 0) % sign assignment
            di = -1;
        else
            di = 1;
        end
        % x, y and z iterations:
        zi = fi(zi - di*ROM(ceil(i/2)), 1, W, F); 
        if (di == 1)
            tmpx = fi(xi + yi*fi(2^(-ceil(i/2)), 1, W, F), 1, W, F);
            tmpy = fi(yi + xi*fi(2^(-ceil(i/2)), 1, W, F), 1, W, F);
        else
            tmpx = fi(xi - yi*fi(2^(-ceil(i/2)), 1, W, F), 1, W, F);
            tmpy = fi(yi - xi*fi(2^(-ceil(i/2)), 1, W, F), 1, W, F) ;   
        end
        xi = tmpx;
        yi = tmpy;
    end
    z = cordicDivide(xi, yi, W, F, iteration); % call cordic-base division
end

function value = cordicDivide(x0, y0, W, F, iteration)
    xi = fi(x0, 1, W, F);
    yi = fi(y0, 1, W, F);
    zi = fi(0, 1, W, F);
    
    for i = 1 : iteration % not using dobule interation 
        if (yi < 0)
            di = 1;
        else
            di = -1;
        end
        % z, x and y equations for division calucaltion:
        zi = fi(zi - di*(2^(-i)), 1, W, F);
        if (di == 1)
            yi = fi(yi + xi*fi(2^(-i), 1, W, F), 1, W, F);
        else
            yi = fi(yi - xi*fi(2^(-i), 1, W, F), 1, W, F);
        end
    end
    value = zi;
end