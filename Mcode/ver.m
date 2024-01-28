## Copyright (C) 2005-2018 William Poetra Yoga Hadisoeseno
## Copyright (C) 2019 Andrew Janke
##
## This file is part of Octave.app, a distribution of GNU Octave.
##
## Octave is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## Octave is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with Octave; see the file COPYING.  If not, see
## <https://www.gnu.org/licenses/>.

## This is Octave.app's custom modification of Octave's ver() function.
## It is extended to pick up the Octave.app release information.

## -*- texinfo -*-
## @deftypefn  {} {} ver
## @deftypefnx {} {} ver Octave
## @deftypefnx {} {} ver @var{package}
## @deftypefnx {} {v =} ver (@dots{})
##
## Display a header containing the current Octave version number, license
## string, and operating system.  The header is followed by a list of installed
## packages, versions, and installation directories.
##
## Use the package name @var{package} or Octave to limit the listing to a
## desired component.
##
## When called with an output argument, return a vector of structures
## describing Octave and each installed package.  The structure includes the
## following fields.
##
## @table @code
## @item Name
## Package name.
##
## @item Version
## Version of the package.
##
## @item Release
## Release of the package.
##
## @item Date
## Date of the version/release.
## @end table
##
## @seealso{version, usejava, pkg}
## @end deftypefn

## Author: William Poetra Yoga Hadisoeseno <williampoetra@gmail.com>

function retval = ver (package = "")

  if (nargin > 1)
    print_usage ();
  endif

  if (nargout == 0)
    hg_id = __octave_config_info__ ("hg_id");

    [unm, err] = uname ();

    if (err)
      os_string = "unknown";
    else
      os_string = sprintf ("%s %s %s %s",
                           unm.sysname, unm.release, unm.version, unm.machine);
    endif

    hbar(1:70) = "-";
    desc = {hbar
            ["GNU Octave Version: " OCTAVE_VERSION " (hg id: " hg_id ")"]
            ["Octave.app Version: " octave_app_release]
            ["GNU Octave License: " license]
            ["Operating System: " os_string]
            hbar};

    printf ("%s\n", desc{:});

    if (isempty (package))
      pkg ("list");
    elseif (strcmpi (package, "Octave"))
      ## Nothing to do, Octave version was already reported
    else
      pkg ("list", package);
    endif
  else
    ## Get the installed packages
    if (isempty (package))
      lst = pkg ("list");
      ## Start with the version info for Octave
      retval = struct ("Name", "Octave", "Version", version,
                       "Release", [],
                       "Date", __octave_config_info__ ("release_date"));
      for i = 1:numel (lst)
        retval(end+1) = struct ("Name", lst{i}.name, "Version", lst{i}.version,
                                "Release", [], "Date", lst{i}.date);
      endfor
    elseif (strcmpi (package, "Octave"))
      retval = struct ("Name", "Octave", "Version", version,
                       "Release", [], "Date", []);
    else
      lst = pkg ("list", package);
      if (isempty (lst))
        retval = struct ("Name", {}, "Version", {},
                         "Release", {}, "Date", {});
      else
        retval = struct ("Name", lst{1}.name, "Version", lst{1}.version,
                         "Release", [], "Date", lst{1}.date);
      endif
    endif
  endif

endfunction

function v = ver (package = "")

  if (nargout == 0)
    # Octave.app customization
    # HACK: We know this lives in share/octave/site/m, so just look up a dir
    my_dir = fileparts (mfilename ("fullpath"));
    my_site_dir = fileparts (my_dir);
    octave_app_release_file = fullfile (my_site_dir, "Octave.app-RELEASE.txt");
    octave_app_release = readOctaveAppReleaseFile (octave_app_release_file);
    # end Octave.app customization

    hg_id = __octave_config_info__ ("hg_id");

    [unm, err] = uname ();

    if (err)
      os_string = "unknown";
    else
      os_string = sprintf ("%s %s %s %s",
                           unm.sysname, unm.release, unm.version, unm.machine);
    endif

    hbar(1:70) = "-";
    # Octave.app customization
    desc = {hbar
            ["GNU Octave Version: " OCTAVE_VERSION " (hg id: " hg_id ")"]
            ["Octave.app Version: " octave_app_release]
            ["GNU Octave License: " license]
            ["Operating System: " os_string]
            hbar};
    # end Octave.app customization

    printf ("%s\n", desc{:});

    if (isempty (package))
      pkg ("list");
    elseif (strcmpi (package, "Octave"))
      ## Nothing to do, Octave version was already reported
    else
      pkg ("list", package);
    endif
  else
    ## Return outputs rather than displaying summary to screen.
    if (isempty (package))
      ## Start with the version info for Octave
      [octver, octdate] = version ();
      v = struct ("Name", "Octave", "Version", octver,
                  "Release", [], "Date", octdate);
      lst = pkg ("list");
      for i = 1:numel (lst)
        v(end+1) = struct ("Name", lst{i}.name, "Version", lst{i}.version,
                           "Release", [], "Date", lst{i}.date);
      endfor
    elseif (strcmpi (package, "Octave"))
      [octver, octdate] = version ();
      v = struct ("Name", "Octave", "Version", octver,
                  "Release", [], "Date", octdate);
    else
      lst = pkg ("list", package);
      if (isempty (lst))
        v = struct ("Name", {}, "Version", {}, "Release", {}, "Date", {});
      else
        v = struct ("Name", lst{1}.name, "Version", lst{1}.version,
                    "Release", [], "Date", lst{1}.date);
      endif
    endif
  endif

endfunction

function out = readOctaveAppReleaseFile (file)
  [fid, msg] = fopen (file);
  if fid < 0
    out = '<unknown (missing Octave.app-RELEASE.txt file)>';
    return;
  endif
  RAII.fid = onCleanup (@() fclose (fid));
  txt = fread (fid, Inf, 'char=>char');
  txt = txt';
  txt = regexprep (txt, '\s*$', '');
  out = txt;
end


%!test
%! result = ver;
%! assert (result(1).Name, "Octave");
%! assert (result(1).Version, OCTAVE_VERSION ());
%! assert (result(1).Release, []);
%! assert (result(1).Date, __octave_config_info__ ("release_date"));
%! result = ver ("octave");
%! assert (result.Name, "Octave");
%! assert (result.Version, OCTAVE_VERSION ());
%! assert (result.Release, []);
%! assert (result.Date, __octave_config_info__ ("release_date"));

%!test
%! lst = pkg ("list");
%! for n = 1:numel (lst)
%!   expected = lst{n}.name;
%!   result = ver (expected);
%!   assert (result.Name, expected);
%!   assert (isfield (result, "Version"), true);
%!   assert (isfield (result, "Release"), true);
%!   assert (isfield (result, "Date"), true);
%! endfor

%!test
%! result = ver ("%_an_unknown_package_%");
%! assert (isempty (result), true);
