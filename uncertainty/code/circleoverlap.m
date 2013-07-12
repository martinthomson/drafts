function Ao = circleoverlap(r1, r2, d)
  if (d >= r1 + r2)
    Ao = 0;
  elseif d <= abs(r1 - r2)
    if (r1 < r2)
      Ao = pi * r1^2;
    else
      Ao = pi * r2^2;
    endif
  else
    a = (r1^2 - r2^2 + d^2) / 2 / d;
    Ao = r1^2 * acos(a/r1) + r2^2*acos((d - a)/r2) - d*sqrt(r1^2 - a^2);
  endif
endfunction
