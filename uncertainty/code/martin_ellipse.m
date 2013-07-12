stddev_x = 5; # the standard deviation of the results
stddev_y = 5;
a = 5;
b = 5;
intervals = 500;
integral = 0;

coeff = a*b/(2*pi*stddev_x*stddev_y);

## work out the values of the function at the interval points

## work out the one at zero first (cant do it in the for loop)

term1 = 1/((a/stddev_x)^2);
term2 = term1 * exp((-1/2)*((a/stddev_x)^2));

f(1) = term1 - term2;

for i = [2:intervals+1]
  term1 = 1/((a*cos(2*pi*(i-1)/intervals)/stddev_x)^2 + (b*sin(2*pi*(i-1)/intervals)/stddev_y)^2);
  term2 = term1 * exp(-1/2*((a*cos(2*pi*(i-1)/intervals)/stddev_x)^2 + (b*sin(2*pi*(i-1)/intervals)/stddev_y)^2));
  f(i) = term1 - term2;
endfor

for i = [1:intervals]
  integral = integral + ((1/2)*(2*pi/intervals)*(f(i)+f(i+1)));
endfor

integral = coeff * integral
