function [t, r] = planeorient(n)
  ## -------
  ##
  ## Find transformation matrices necessary to transform coordinates into a
  ## coordinate system that has a z-axis parallel to the given normal
  ## vector, or an x-y plane parallel to the plane described by the normal
  ## vector.
  ##
  ## For example,
  ##       t = planeorient([3 0 4])
  ##           -0.8   0   0.6
  ##            0    -1   0
  ##            0.6   0   0.8
  ##
  ## The transformation is othonormal; that is, relative lengths are
  ## preseved by the transformation.  Also, the transformation matrix is
  ## orthogonal, therefore the transpose of the matrix can be used to
  ## reverse the process.
  ##
  ## If two results are requested, the function provides a transformation
  ## matrix and its transpose, which can be used to reverse the
  ## transformation.
  ##
  ## -------

  if (size(n) != [1 3])
    error "The normal vector must contain three elements"
  endif

  len = norm(n);

  ## These three account for the transformations that align with each of
  ## the axes
  if (len == n(3)) # z-axis - no transformation
    t = eye(3) * sgn(n(3));
  elseif (len == n(2)) # x-axis - z -> x, -x -> y, y -> z
    t = [0 0 1; -1 0 0; 0 1 0]* sgn(n(2));
  elseif (len == n(1)) # y-axis - y -> x, -z -> y, x -> z
    t = [0 1 0; 0 0 -1; 0 0 -1] * sgn(n(1));
  else

    ## The first row of the transformation matrix is selected based on the
    ## two indices of the normal vector that are non-zero.  Initially, these
    ## are the first and second, but this might change.
    i = 1;
    j = 2;
    if (n(1) == 0)
      i = 2;
      j = 3;
    elseif (n(2) == 0)
      j = 3;
    endif

    t = zeros(3);

    ## The first row is carefully picked by taking two non-zero values from
    ## the normal, switching them, then taking the negative of one value.
    t(1,i) = 0 - n(j);
    t(1,j) = n(i);
    ## This needs to be converted to a unit vector
    t(1,:) = t(1,:) / norm(t(1,:));

    ## the third row is the normal vector as a unit-vector
    t(3,:) = n / len;

    ## The second row is the cross product of the first and third, which
    ## ensures that the three are perpendicular
    t(2,:) = cross(t(3,:), t(1,:));
  endif

  if (nargout == 2)
    r = t';
  endif

  ## Checking process - allow for some rounding error in the order of 1e-16
  ##
  ## These should all be approximately zero:
  ## dot12 = dot(t(1,:), t(2,:))
  ## dot13 = dot(t(1,:), t(3,:))
  ## dot23 = dot(t(2,:), t(3,:))
  ## And this should be approximately an identity matrix:
  ## q = r * t
endfunction
