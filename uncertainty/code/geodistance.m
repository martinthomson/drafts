function d = geodistance(a, b, degreeflag)
  if (nargin == 2)
    degreeflag = 0;
  endif
  darr = geo2ecef(a, degreeflag) - geo2ecef(b, degreeflag);
  d = norm(darr);
endfunction
