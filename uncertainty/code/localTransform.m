% USAGE:
%   local = localTransform(wgsreference, orientation, wgspoint[, deg])
%
% local = matrix with 2 or 3 columns: [x y {z}; x2 y2 {z2}; ...]
% wgsreference = vector with 3 values only [lat lng alt]
% orientation = scalar angle
% wgspoint = matrix with 2 or 3 columns: [lat lng {alt}; lat2 lng2 {alt2}; ...]
% deg = degrees indicator
function local = localTransform(wgsreference, orientation, wgspoint, deg)

  altitude = 1;
  if (size(wgspoint)(2) == 2)
    altitude = 0;
    wgspoint = cat(2, wgspoint, zeros([size(wgspoint)(1) 1]));
  endif

  ecefRef = geo2ecef(wgsreference,deg);
  ecef = geo2ecef(wgspoint,deg);

  if (nargin == 4 && deg == 1)
    % drop altitude from reference pt - not needed
    wgsreference = wgsreference(:,1:2) * pi / 180;
    orientation = orientation * pi / 180;
  endif

  cosref = cos(wgsreference);
  sinref = sin(wgsreference);
  T0 = [-sinref(2) cosref(2) 0; -sinref(1)*cosref(2) -sinref(1)*sinref(2) cosref(1); cosref(1)*cosref(2) cosref(1)*sinref(2) sinref(1)];

  coso = cos(orientation);
  sino = sin(orientation);
  R = [coso -sino 0; sino coso 0; 0 0 1];

  T = R * T0

  col = ones([size(ecef)(1) 1]);
  diff = ecef - cat(2, ecefRef(1) * col, ecefRef(2) * col, ecefRef(3) * col)

  local = (T * diff')';
  local = diff * T';
endfunction
