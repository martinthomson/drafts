function c = polygoncentroid3d(p, h)
  if (nargin == 1)
    h = 0;
  endif


  if (size(p)(1) < 3)
    error "Need at least three points to make a polygon";
  endif
  if (size(p)(2) == 2)
    c = polygoncentroid(p);
    return
  endif

  if (size(p)(2) != 3)
    error "Only two and three dimensional polygons supported";
  endif

  n = polygonnormal(p)   # find an approximate normal (unit-)vector
  t = planeorient(n)  # find transformation matrices

  p2 = (t * (p'))'   # translate to new coordinate system

  area = polygonarea(p2(:, 1:2))  # the area of a 2d polygon
  c2 = polygoncentroid(p2(:, 1:2))  # the centroid of a 2d polygon
  z = sum(p2(:, 3)) / size(p2)(1) + h / 2  # the average z value

  c = ((t') * ([c2, z]'))'
endfunction
