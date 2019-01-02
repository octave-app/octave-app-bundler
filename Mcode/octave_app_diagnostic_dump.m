function octave_app_diagnostic_dump
  %OCTAVE_APP_DIAGNOSTIC_DUMP Create a diagnostic dump for Octave.app
  %
  % Creates a file containing a diagnostic dump about this Octave.app installation
  % and the environment it is running in.
  
  outfile = 'octave_app_diagnostic_dump.txt';
  [fid,errmsg] = fopen(outfile, 'w');
  if ~fid
    error('Failed opening output file ''%s'' for writing: %s', outfile, errmsg);
  end
  
  printf('Creating diagnostic dump. Please be patient...\n');
  do_it;
  fclose(fid);
  printf('Dump complete. Output file is: %s\n', outfile);
  
  function p(varargin)
    if nargin < 1; varargin = {''}; end
    fprintf(fid, varargin{:});
    fprintf(fid, '\n');
  end
  
  function section(name)
    p(name);
    p('-----------------------------------');
    p();
  end
  
  function do_it
    % Locate ourselves
    mroot = matlabroot;
    app_root = fileparts(fileparts(fileparts(fileparts(fileparts(fileparts(mroot))))));
    
    p('Octave.app diagnostic dump')
    p('Created: %s', datestr(now))
    [status,txt] = system('hostname');
    txt = chomp(txt);
    p('Host: %s' , txt);
    p
    
    % Octave version and state
    section('Octave.app')
    p(evalc('ver'))
    p
    p('Java:')
    p(evalc('version -java'))
    p
    p('matlabroot: %s', matlabroot)
    % Doing a shasum with tar makes it fast enough to be tolerable
    [status,txt] = system(sprintf('cd %s; tar c . | shasum -a 256', app_root));
    p('Octave.app shasum: %s', txt)
    
    % System
    section('System')
    [status,txt] = system('sw_vers');
    p('sw_vers:\n%s', txt);
    
    % Environment
    
    % Enumerate expected-safe environment vars, to avoid possibly exposing 
    % confidential user information.
    section('Environment');
    p('Environment:')
    env_vars = {
      'CC'
      'COLORTERM'
      'COMMAND_MODE'
      'F77'
      'FC'
      'GNUTERM'
      'GS'
      'GS_OPTIONS'
      'HOME'
      'LANG'
      'LC_COLLATE'
      'LC_CTYPE'
      'LC_MESSAGES'
      'LC_MONETARY'
      'LC_NUMERIC'
      'LC_TIME'
      'LC_ALL'
      'LD_LIBRARY_PATH'
      'PATH'
      'PWD'
      'SHELL'
      'TERM'
      'TMPDIR'
      'USER'      
    };
    for i = 1:numel(env_vars)
      p('%s: %s', env_vars{i}, getenv(env_vars{i}))
    end
    p
    p('Locale:')
    [status,txt] = system('locale');
    p(txt)
    
    % Homebrew
    section('Homebrew')
    [status,txt] = system('which brew');
    if status == 0
      brew_cmd = chomp(txt);
    else
      brew_cmd = '/usr/local/bin/brew';
    end
    if exist(brew_cmd) == 2
      [status,txt] = system(sprintf('%s config', brew_cmd));
      p('brew config:\n%s', txt)
      [status,txt] = system(sprintf('%s doctor 2>&1', brew_cmd));
      p('brew doctor:\n%s', txt)
    end
    
    % Compilation stuff
    section('Compilation stuff')
    p('mkoctfile configuration:')
    mkoct_vars = {
      'ALL_CFLAGS'
      'ALL_CXXFLAGS'
      'ALL_FFLAGS'
      'ALL_LDFLAGS'
      'AR'
      'BLAS_LIBS'
      'CC'
      'CFLAGS'
      'CPICFLAG'
      'CPPFLAGS'
      'CXX'
      'CXXFLAGS'
      'CXXPICFLAG'
      'DEPEND_EXTRA_SED_PATTERN'
      'DEPEND_FLAGS'
      'DL_LD'
      'DL_LDFLAGS'
      'F77'
      'F77_INTEGER8_FLAG'
      'FFLAGS'
      'FFTW3F_LDFLAGS'
      'FFTW3F_LIBS'
      'FFTW3_LDFLAGS'
      'FFTW3_LIBS'
      'FFTW_LIBS'
      'FLIBS'
      'FPICFLAG'
      'INCFLAGS'
      'INCLUDEDIR'
      'LAPACK_LIBS'
      'LD_CXX'
      'LDFLAGS'
      'LD_STATIC_FLAG'
      'LFLAGS'
      'LIBDIR'
      'LIBOCTAVE'
      'LIBOCTINTERP'
      'LIBS'
      'OCTAVE_HOME'
      'OCTAVE_LIBS'
      'OCTAVE_LINK_DEPS'
      'OCTAVE_LINK_OPTS'
      'OCTAVE_PREFIX'
      'OCTINCLUDEDIR'
      'OCTLIBDIR'
      'OCT_LINK_DEPS'
      'OCT_LINK_OPTS'
      'RANLIB'
      'RDYNAMIC_FLAG'
      'READLINE_LIBS'
      'SED'
      'SPECIAL_MATH_LIB'
      'XTRA_CFLAGS'
      'XTRA_CXXFLAGS'
    };
    for i = 1:numel(mkoct_vars)
      var = mkoct_vars{i};
      txt = chomp(mkoctfile('-p', var));
      p('%s: %s', var, txt);
    end
    p
    p('octave_config_info:')
    p(evalc('octave_config_info'))
    
    % pkg
    % Unnecessary since 'ver' output includes it
    % section('pkg')
    % p('pkg list:')
    % installed = pkg('list');
    % for i = 1:numel(installed)
    %   pk = installed{i};
    %   p('%s %s: %s', pk.name, pk.version, pk.dir);
    % end
  end
  
end

function str = chomp(str)
  if isempty(str)
    return;
  end
  if str(end) == sprintf('\n')
    str(end) = [];
  end
end
