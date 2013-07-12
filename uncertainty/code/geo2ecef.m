% LLA2ECEF - convert latitude, longitude, and altitude to
%            earth-centered, earth-fixed (ECEF) cartesian
%
% USAGE:
% xyz = geo2ecef(lla[, deg])
%
% xyz = ECEF coordinates [x y z; ...]
% lla = Geodetic coordinates [latitude longitude altitude; ...]
% deg = optional degrees marker, if present and 1 lla is degrees, else lla is radians
%
% Notes: This function assumes the WGS84 model.
%        Latitude is customary geodetic (not geocentric).
%
% Source: "Department of Defense World Geodetic System 1984"
%         Page 4-4
%         National Imagery and Mapping Agency
%         Last updated June, 2004
%         NIMA TR8350.2
%
% Michael Kleder, July 2005

function xyz = geo2ecef(lla, deg)

  lat = lla(:,1);
  lng = lla(:,2);
  alt = lla(:,3);

  if (nargin == 2 && deg == 1)
    lat = lat * pi / 180;
    lng = lng * pi / 180;
  endif


  ## WGS84 ellipsoid constants:
  a = 6378137;
  f = 1.0 / 298.257223563;
  e2 = f * (2.0 - f);

  ## intermediate calculation
  ## (prime vertical radius of curvature)
  N = a ./ sqrt(1 - e2 .* sin(lat) .^ 2);

  ## results:
  x = (N + alt) .* cos(lat) .* cos(lng);
  y = (N + alt) .* cos(lat) .* sin(lng);
  z = ((1 - e2) .* N + alt) .* sin(lat);

  xyz = [x, y, z];

endfunction
