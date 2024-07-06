function diagnostic_dump(varargin)
  %DIAGNOSTIC_DUMP Create a diagnostic dump for Octave.app
  %
  % octapp.diagnostic_dump()
  %
  % Creates a file containing a diagnostic dump about this Octave.app installation
  % and the environment it is running in. This is useful for giving to the Octave.app
  % maintainers when reporting a bug or issue with Octave.app.
  %
  % The output is a human-readable (well, programmer-readable) file with a bunch of
  % info in it. The file is not machine-readable, and its exact format is not
  % specified and may change over time.

  % Backdoor options:
  %   octapp.diagnostic_dump -stdout  - display to stdout instead of a file

  if (ismember ("-stdout", varargin))
    outfile = "<stdout>";
    fid = 1;
  else
    outfile = "octave_app_diagnostic_dump.txt";
    [fid, errmsg] = fopen (outfile, "w");
    if (! fid)
      error ("Failed opening output file '%s' for writing: %s", outfile, errmsg);
    endif
  endif

  printf ("Creating Octave.app diagnostic dump. Please be patient...\n");
  do_it;
  if (fid > 2)
    fclose (fid);
  endif
  printf ("Diagnostic dump complete. Output file is: %s\n", outfile);

  function p (varargin)
    if (nargin < 1); varargin = {""}; endif
    fprintf (fid, varargin{:});
    fprintf (fid, "\n");
  endfunction

  function section (name)
    p ();
    p (name);
    p ("-----------------------------------");
    p ();
  endfunction

  function do_it ()
    % Locate ourselves
    mroot = matlabroot;
    % Wow what a kludge
    app_root = fileparts (fileparts (fileparts (fileparts (fileparts (fileparts (mroot))))));

    p ("Octave.app diagnostic dump")
    p ("Created: %s", datestr(now))
    p

    section ("Notes")
    p ("Note to maintainers: Paths in this dump have been sanitized. User HOME paths have been")
    p ("replaced with ""~"". A ""~"" might not have been a literal tilde in the original value.")
    p ("User name has also been sanitized, and replaced with ""${USER}"".")
    p

    % Octave version and state
    section ("Octave.app")
    p ("Sanitized ver:")
    sanitized_ver = sanitize_path_strs(evalc("ver"));
    p (sanitized_ver)
    p
    blas_ver = version("-blas");
    p ("BLAS: %s", blas_ver);
    lapack_ver = version("-lapack");
    p ("LAPACK: %s", lapack_ver);
    fftw_ver = version("-fftw");
    p ("FFTW: %s", fftw_ver)
    java_ver = version("-java");
    p ("Java: %s", java_ver)
    p
    p ("matlabroot: %s", sanitize_path_strs(matlabroot))
    % Doing a shasum with tar makes it fast enough to be tolerable
    [status, txt] = system (sprintf ("cd %s; tar c . | shasum -a 256 | cut -d ' ' -f 1", app_root));
    p ("Octave.app shasum: %s", txt)

    % System
    section ("System")
    [status, txt] = system("sw_vers");
    p ("sw_vers:\n%s", txt);

    % Environment

    % Enumerate expected-safe environment vars, to avoid possibly exposing
    % confidential user information.
    section ("Environment");
    p ("Environment:")
    env_vars = {
      "CC"
      "COLORTERM"
      "COMMAND_MODE"
      "F77"
      "FC"
      "GNUTERM"
      "GS"
      "GS_OPTIONS"
      "LANG"
      "LC_COLLATE"
      "LC_CTYPE"
      "LC_MESSAGES"
      "LC_MONETARY"
      "LC_NUMERIC"
      "LC_TIME"
      "LC_ALL"
      "LD_LIBRARY_PATH"
      "PATH"
      "PWD"
      "SHELL"
      "TERM"
      "TMPDIR"
    };
    for i = 1:numel (env_vars)
      p ("%s: %s", env_vars{i}, sanitize_path_strs (getenv (env_vars{i})))
    endfor
    p
    p ("Path:")
    path_str = getenv ("PATH");
    path_els = strsplit (path_str, ":");
    path_els = sanitize_path_strs (path_els);
    for i = 1:numel (path_els)
      p ("  %s", path_els{i});
    endfor
    p
    p ("Locale:")
    [status, txt] = system ("locale");
    p (txt)
    p
    p ("Resolved commands:")
    cmds = {
      "clang"
      "clang++"
      "gcc"
      "g++"
      "make"
      "mkoctfile"
      "tar"
    };
    for i = 1:numel(cmds)
      [status, txt] = system (sprintf ("which %s", cmds{i}));
      p ("%s: %s", cmds{i}, sanitize_path_strs (chomp (txt)))
    endfor

    % System Homebrew
    section ("System Homebrew")
    [status, txt] = system ("which brew");
    if (status == 0)
      brew_cmd = chomp (txt);
    else
      arch = computer("arch");
      if strcmp(arch(end-6:end), "-x86_64")
        brew_cmd = "/usr/local/bin/brew";
      else
        brew_cmd = "/opt/homebrew/bin/brew";
      endif
    endif
    if (exist (brew_cmd) == 2)
      [status, txt] = system (sprintf ("%s config", brew_cmd));
      p ("brew config:\n%s", sanitize_path_strs(txt))
      [status, txt] = system (sprintf ("%s doctor 2>&1", brew_cmd));
      p ("brew doctor:\n%s", sanitize_path_strs (txt))
    else
      p ("No system Homebrew installation found.")
    endif

    % Compilation stuff
    section ("Compilation stuff")
    p ("mkoctfile configuration:")
    mkoct_vars = {
      "ALL_CFLAGS"
      "ALL_CXXFLAGS"
      "ALL_FFLAGS"
      "ALL_LDFLAGS"
      "AR"
      "BLAS_LIBS"
      "CC"
      "CFLAGS"
      "CPICFLAG"
      "CPPFLAGS"
      "CXX"
      "CXXFLAGS"
      "CXXPICFLAG"
      "DEPEND_EXTRA_SED_PATTERN"
      "DEPEND_FLAGS"
      "DL_LD"
      "DL_LDFLAGS"
      "F77"
      "F77_INTEGER8_FLAG"
      "FFLAGS"
      "FFTW3F_LDFLAGS"
      "FFTW3F_LIBS"
      "FFTW3_LDFLAGS"
      "FFTW3_LIBS"
      "FFTW_LIBS"
      "FLIBS"
      "FPICFLAG"
      "INCFLAGS"
      "INCLUDEDIR"
      "LAPACK_LIBS"
      "LD_CXX"
      "LDFLAGS"
      "LD_STATIC_FLAG"
      "LFLAGS"
      "LIBDIR"
      "LIBOCTAVE"
      "LIBOCTINTERP"
      "LIBS"
      "OCTAVE_HOME"
      "OCTAVE_LIBS"
      "OCTAVE_LINK_DEPS"
      "OCTAVE_LINK_OPTS"
      "OCTAVE_PREFIX"
      "OCTINCLUDEDIR"
      "OCTLIBDIR"
      "OCT_LINK_DEPS"
      "OCT_LINK_OPTS"
      "RANLIB"
      "RDYNAMIC_FLAG"
      "READLINE_LIBS"
      "SED"
      "SPECIAL_MATH_LIB"
      "XTRA_CFLAGS"
      "XTRA_CXXFLAGS"
    };
    for i = 1:numel (mkoct_vars)
      var = mkoct_vars{i};
      txt = chomp (mkoctfile ("-p", var));
       p("%s: %s", var, sanitize_path_strs (txt));
    endfor
    p
    p ("__octave_config_info__:")
    p (sanitize_path_strs (evalc ("__octave_config_info__")))

    % pkg
    % Unnecessary since "ver" output includes it
    % section ("pkg")
    % p ("pkg list:")
    % installed = pkg ("list");
    % for i = 1:numel (installed)
    %   pk = installed{i};
    %   p ("%s %s: %s", pk.name, pk.version, pk.dir);
    % endfor
  endfunction

endfunction

function str = chomp (str)
  if (isempty (str))
    return
  endif
  if (str(end) == sprintf ("\n"))
    str(end) = [];
  endif
endfunction

function out = sanitize_path_strs (in)
  persistent replacements
  if (isempty (replacements))
    replacements = {
      getenv("HOME")    "~"
      getenv("USER")    "${USER}"
      matlabroot        "<OCTAVE_ROOT>"
      getenv("HOST")    "${HOST}"
    };
  endif

  if (iscell (in))
    out = cellfun (@sanitize_path_strs, in, "UniformOutput", false);
  elseif (isstruct (in))
    out = structfun (@sanitize_path_strs, in, "UniformOutput", false);
  elseif (isnumeric (in) || islogical (in))
    out = in;
  elseif (ischar (in))
    out = in;
    for i = 1:size (replacements, 1)
      [orig, repl] = replacements{i,:};
      out = strrep (out, orig, repl);
    endfor
  else
    error ("%s: invalid input type: %s", "sanitize_path_strs", class (str));
  endif
endfunction
