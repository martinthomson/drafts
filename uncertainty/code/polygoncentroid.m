function c = polygoncentroid(p)

  ## This method uses a few hacks to implement the centroid calculation for
  ## a polygon.  The two shifted matrices enable the use of .* to get
  ## values like x[i]*x[i+1] and x[i]*y[i+1]
  q = shift(p, -1, 1);
  r = shift(q, 1, 2);

  xx1 = p + q;    # (x[i] + x[i+1]) and (y[i] + y[i+1])
  xx2 = p .* r;   # (x[i] * y[i+1]) and (y[i] * x[i+1])
  ## (x[i] * y[i+1]) - (y[i] * x[i+1]):
  xx3 = xx2 * [1 1; -1 -1];

  c = sum(xx1 .* xx3) / 6 / polygonarea(p);
endfunction
