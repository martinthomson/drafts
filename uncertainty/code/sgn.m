function s = sgn(x)
  ## Find the sign of the given value
  ## Returns 1 if x > 0; 0 if x == 0; -1 if x < 0
  s = (x != 0) .* (x > 0) * 2 - 1;
endfunction
