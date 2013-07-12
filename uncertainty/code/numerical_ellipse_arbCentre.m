## constant definitions.  Tweak these to tweak behaviour.
stddev_x = 1; # the standard deviation of the results
stddev_y = 1;
cx = 0; # the centre of the ellipse
cy = 0;
a = 1; # the major and minor axes of the ellipse
b = 1;
intr = 200; # the number of intervals to perform the numerical integration over
intt = 200;

# Calculate all the points within the integration domain
sum = 0;
for i = [1:intr]
  r = (i-1)/intr;
  for j = [1:intt]
    t = (j-1)*(2*pi)/intt;
    z(i,j) = exp((-1/2)*(((a*r*cos(t) + cx)/stddev_x)^2 + (((b*r*sin(t) + cy)/stddev_y)^2)))*r;
    sum = sum + z(i,j)*(2*pi/(intr*intt));
  endfor
endfor

integral = ((a*b)/(2*pi*stddev_x*stddev_y))*sum
