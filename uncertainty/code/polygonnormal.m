function n = polygonnormal(p)
  if (size(p)(1) < 3)
    error "Need at least three points to make a polygon";
  endif
  if (size(p)(2) != 3)
    error "Only three dimensional polygons supported";
  endif

  tmp = shift(p, -1, 1) - shift(p, 1, 1);  # (x[i+1] - x[i-1])
  tmp = shift(p, -1, 2) .* shift(tmp, 1, 2); # (y[i] * dz)

  nx = sum(tmp, 1);

  n = nx / norm(nx);
endfunction
