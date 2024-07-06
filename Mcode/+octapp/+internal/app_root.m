function out = app_root
  %APP_ROOT Locate the root of the app bundle for this Octave session.
  %
  % out = octapp.internal.app_root
  %
  % Detects the root of the Octave.app app bundle this Octave session is running from.
  %
  % This is based on the image for the Octave session (as indicated by matlabroot), not
  % the location of the source file for this app_root function.
  %
  % Returns the path to the app bundle root as a string, or [] if it does not look like
  % this is running from an app bundle, or there was some other problem in detection.

  persistent result is_init
  if isempty (is_init)
    result = app_root_impl;
    is_init = true;
  endif
  out = result;
endfunction

function out = app_root_impl
  mroot = matlabroot;
  mroot_parts = strsplit (mroot, '/');
  mroot_parts(1) = [];
  mroot_parts;

  app_root = [];

  nparts = numel (mroot_parts);
  for i_part = nparts:-1:1
    part_name = mroot_parts{i_part};
    [par, stem, extn] = fileparts (part_name);
    if (! isequal (extn, '.app'))
      continue
    endif
    % Found dir with an app bundle name; check for app bundle metadata files
    app_cand = fullfile ('/', mroot_parts{1:i_part});
    expect_files_rel = {'Info.plist', 'PkgInfo', 'MacOS/applet'};
    expect_files = fullfile (app_cand, 'Contents', expect_files_rel);
    if (all (isfile (expect_files)))
      app_root = app_cand;
      break
    endif
  endfor

  out = app_root;

endfunction
