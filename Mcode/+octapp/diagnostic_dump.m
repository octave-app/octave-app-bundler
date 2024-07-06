function diagnostic_dump(varargin)
  %DIAGNOSTIC_DUMP Create a diagnostic dump for Octave.app
  %
  % octapp.diagnostic_dump [...options...]
  %
  % Creates a file containing a diagnostic dump about this Octave.app installation
  % and the environment it is running in. This is useful for giving to the Octave.app
  % maintainers when reporting a bug or issue with Octave.app.
  %
  % The output is a human-readable (well, programmer-readable) file with a bunch of
  % info in it. The file is not machine-readable, and its exact format is not
  % specified and may change over time.
  %
  % The arguments to this function are all command-style strings.
  %
  % Options:
  %
  %   -outfile <file>  - The output file to write to. If not given, a name is chosen
  %       automatically, in a form like "octapp_diag_<version>_<date>.txt". You can also
  %       pass "-" for <file> to write to stdout (the console) instead of a file.
  %
  %   -stdout  - Display to stdout instead of writing to a file. This is equivalent to
  %       '-outfile -'.

  opts = parse_args(varargin);

  timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
  if (isequal (opts.outfile, "-"))
    outfile = "<stdout>";
    fid = 1;
  else
    if (! isempty (opts.outfile))
      outfile = opts.outfile;
    else
      outfile = sprintf ("octapp_diag_%s_%s.txt", version, timestamp);
    endif
    [fid, errmsg] = fopen (outfile, "w");
    if (! fid)
      error ("Failed opening output file '%s' for writing: %s", outfile, errmsg);
    endif
  endif

  printf ("Creating Octave.app diagnostic dump. Please be patient...\n");
  t0 = tic;
  do_it;
  if (fid > 2)
    fclose (fid);
  endif
  te = toc(t0);
  printf ("Diagnostic dump complete in %0.3f s.\n", te);
  printf ("Output file: %s\n", outfile);

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
    mroot_parts = strsplit (mroot, '/');
    mroot_parts(1) = [];
    % Wow what a kludge
    if (isequal (mroot_parts{1}, "Applications"))
      is_app = true;
      app_root = fullfile ("/", mroot_parts{1:2});
    else
      is_app = false;
      app_root = [];
    endif

    p ("Octave.app diagnostic dump")
    p ("Created at: %s", datestr(now))
    p

    section ("Notes")
    p ("Note to maintainers: Paths in this dump have been sanitized. User HOME paths have been")
    p ("replaced with ""~"". A ""~"" might not have been a literal tilde in the original value.")
    p ("User name has also been sanitized, and replaced with ""${USER}"".")
    p

    % Octave version and state
    section ("Octave.app")
    p ("Sanitized ver:")
    sanitized_ver = sanitize_path_strs (evalc ("ver"));
    p (sanitized_ver)
    p
    blas_ver = version ("-blas");
    p ("BLAS: %s", blas_ver);
    lapack_ver = version ("-lapack");
    p ("LAPACK: %s", lapack_ver);
    fftw_ver = version ("-fftw");
    p ("FFTW: %s", fftw_ver)
    java_ver = version ("-java");
    p ("Java: %s", java_ver)
    p
    p ("matlabroot: %s", mroot)
    if (! is_app)
      p ("App root: <n/a> (does not look like an app under /Applications)")
    else
      p ("App root: %s", app_root)
      % Doing a shasum with tar makes it fast enough to be tolerable
      [status, txt] = system (sprintf ("cd '%s'; /usr/bin/tar c . | shasum -a 256 | cut -d ' ' -f 1", app_root));
      p ("Octave.app shasum: %s", txt)
    end

    % System
    section ("System")
    [status, txt] = system ("sw_vers");
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
      if strcmp (arch(end-6:end), "-x86_64")
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

    mkoct_varsets = {
      {"Main vars", {
        "ALL_CFLAGS"
        "ALL_CXXFLAGS"
        "ALL_FFLAGS"
        "ALL_LDFLAGS"
        "BLAS_LIBS"
        "CC"
        "CFLAGS"
        "CPICFLAG"
        "CPPFLAGS"
        "CXX"
        "CXXFLAGS"
        "CXXPICFLAG"
        "DL_LDFLAGS"
        "F77"
        "F77_INTEGER8_FLAG"
        "FFLAGS"
        "FPICFLAG"
        "INCFLAGS"
        "INCLUDEDIR"
        "LAPACK_LIBS"
        "LDFLAGS"
        "LD_STATIC_FLAG"
        "LIBDIR"
        "LIBOCTAVE"
        "LIBOCTINTERP"
        "OCTAVE_LIBS"
        "OCTAVE_LINK_DEPS"
        "OCTAVE_LINK_OPTS"
        "OCTINCLUDEDIR"
        "OCTLIBDIR"
        "OCT_LINK_DEPS"
        "OCT_LINK_OPTS"
        "RDYNAMIC_FLAG"
        "SPECIAL_MATH_LIB"
        "XTRA_CFLAGS"
        "XTRA_CXXFLAGS"
      }},

      {'"Currently unused" vars', {
        "AR"
        "DEPEND_EXTRA_SED_PATTERN"
        "DEPEND_FLAGS"
        "FFTW3F_LDFLAGS"
        "FFTW3F_LIBS"
        "FFTW3_LDFLAGS"
        "FFTW3_LIBS"
        "FFTW_LIBS"
        "FLIBS"
        "LIBS"
        "RANLIB"
        "READLINE_LIBS"
      }},

      {'"Info-only" vars', {
        "API_VERSION"
        "ARCHLIBDIR"
        "BINDIR"
        "CANONICAL_HOST_TYPE"
        "DATADIR"
        "DATAROOTDIR"
        "DEFAULT_PAGER"
        % EXEC_PREFIX is documented, but mkoctfile raises a warning about it being
        % deprecated, so exclude it to avoid a warning when diag_dump is called.
        % "EXEC_PREFIX"
        "EXEEXT"
        "FCNFILEDIR"
        "IMAGEDIR"
        "INFODIR"
        "INFOFILE"
        "LIBEXECDIR"
        "LOCALAPIARCHLIBDIR"
        "LOCALAPIFCNFILEDIR"
        "LOCALAPIOCTFILEDIR"
        "LOCALARCHLIBDIR"
        "LOCALFCNFILEDIR"
        "LOCALOCTFILEDIR"
        "LOCALSTARTUPFILEDIR"
        "LOCALVERARCHLIBDIR"
        "LOCALVERFCNFILEDIR"
        "LOCALVEROCTFILEDIR"
        "MAN1DIR"
        "MAN1EXT"
        "MANDIR"
        "OCTAVE_EXEC_HOME"
        "OCTAVE_HOME"
        "OCTAVE_VERSION"
        "OCTDATADIR"
        "OCTDOCDIR"
        "OCTFILEDIR"
        "OCTFONTSDIR"
        "STARTUPFILEDIR"
      }}
    };
    for i_set = 1:numel (mkoct_varsets)
      mkoct_varset = mkoct_varsets{i_set};
      [varset_label, mkoct_vars] = mkoct_varset{:};
      p ()
      p ("===== %s =====", varset_label)
      for i_var = 1:numel (mkoct_vars)
        var = mkoct_vars{i_var};
        txt = chomp (mkoctfile ("-p", var));
        p("%s: %s", var, sanitize_path_strs (txt));
      endfor
    endfor
    p
    p ("__octave_config_info__:")
    p (sanitize_path_strs (evalc ("__octave_config_info__")))
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

function opts = parse_args (args)

opts = struct;
opts.outfile = [];
mainfunc = "octapp.diagnostic_dump";

function arg_out = get_opt_arg ()
  if (i >= numel (args))
    error ('%s: option %s requires an argument', mainfunc, arg)
  endif
  arg_out = args{i+1};
  i = i + 1;
endfunction

i = 0;
while i < numel (args)
  i = i + 1;
  arg = args{i};
  switch arg
    case "-stdout"
      opts.outfile = "-";
    case "-outfile"
      opts.outfile = get_opt_arg;
    otherwise
      error ("%s: unrecognized argument: %s", mainfunc, arg)
  endswitch
endwhile

endfunction

