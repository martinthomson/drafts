function a = polygonarea(p)
  if (size(p)(1) < 3)
    error "Need at least three points to make a polygon";
  endif
  if (size(p)(2) != 2)
    error "Only two dimensional polygons are supported";
  endif

  ## Two shifts allow us to align y[i+1] with x[i]
  q = shift(shift(p, -1, 1), 1, 2);
  s = sum(p .* q);  # sum of x[i] * y[i+1]

  a = s * [1;-1] / 2;
endfunction
