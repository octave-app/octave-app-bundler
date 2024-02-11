# apjanke's test suite wrapper

function out = octapp_run_test_suite (varargin)
# Runs test suite, with build & version info, capturing to a log file.
#
# out = octapp_run_test_suite (varargin)
#
# run_type:
#   'wet' - real run
#
# Options (just pass them as string arguments):
#   'dry' - do a dry run that skips the actual tests
#   'profile' - enable profiler and save its results

valid_opts = {'dry', 'profile'};
opts = cellstr (varargin);
bad_opts = setdiff (opts, valid_opts);
if (! isempty (bad_opts))
  error ('invalid options: %s. Valid options are: %s', ...
    strjoin (bad_opts, ', '), strjoin (valid_opts, ', '))
endif
do_profile = ismember ('profile', opts);
do_dry_run = ismember ('dry', opts);

out = struct;

[ok, host_out] = system ('hostname');
host = regexprep (host_out, '\..*', '');
# Timestamp in UTC; now() only gives local time
start_time = gmtime (time ());
timestamp = strftime ('%Y-%m-%d_%H-%M-%S', start_time);
timestamp_friendly = strftime ('%Y-%m-%d %H:%M:%S', start_time);

out_dir = fullfile (getenv ('HOME'), 'octave-tests');
ensure_dir (out_dir);
out_file_base = sprintf ('fntests_%s_%s_%s_%s', ...
  version, host, computer, timestamp);
log_file = fullfile (out_dir, [out_file_base '.log']);
profile_file = fullfile (out_dir, [out_file_base '_profile.mat']);

p ('Running test suite.')
p ('Log file: %s', log_file)
p ('')

RAII.diary = onCleanup (@() diary('off'));
diary (log_file)

# Octave build & environment info
p ('GNU Octave test suite results')
p ('')
p (["This file was produced with %s() from Octave.app's octave-app-bundler (not an " ...
  "official GNU Octave tool)"], mfilename)
p ('')
p ('Octave version: %s', version)
p ('Run: %s on %s (%s)', timestamp_friendly, host, computer)
p ('')
p ('matlabroot: %s', matlabroot)
show_octave_version_info
if ismac
  p ('macOS info (sw_vers):')
  show_system ('sw_vers');
endif
p ('locale:')
show_system ('locale')
p ('__octave_config_info__:')
disp (__octave_config_info__)
p ('')

# Main test suite run
p ('Running __run_test_suite__:')
t0 = tic;
if (do_profile)
  p ('Profiling enabled.')
  profile on
  RAII.profile = onCleanup (@() profile ('off'));
endif
if (do_dry_run)
  p ('DRY RUN: skipped actual test suite run')
else
  __run_test_suite__
endif
if (do_profile)
  profile_info = profile ("info");
  profile off
  save (profile_file, 'profile_info')
  out.profile_info = profile_info;
endif
te = toc (t0);
p ('\n__run_test_suite__ finished in %s.', duration_str (te))
p ('Log file: %s', log_file)
if (do_profile)
  p ('Profile file: %s', profile_file)
endif
p ('')

# Cleanup
diary off
p ('')
if (nargout == 0)
  # Just to avoid spamming command window for regular callers
  clear out
endif

endfunction

function show_octave_version_info ()
p ('ver:')
ver
blas_ver = version('-blas');
p ('BLAS: %s', blas_ver);
lapack_ver = version('-lapack');
p ('LAPACK: %s', lapack_ver);
fftw_ver = version('-fftw');
p ('FFTW: %s', fftw_ver)
java_ver = version('-java');
p ('Java: %s', java_ver)
endfunction

function show_system (cmd)
[ok, txt] = system (cmd);
if (ok != 0)
  p ('command failed: `%s` (exit status = %d). Output:\n%s', cmd, ok, txt)
else
  p ('%s', txt)
endif
endfunction

function ensure_dir (d)
  if isfolder (d)
    return
  endif
  [ok, msg] = mkdir (d);
  if ok != 1
    error ('Failed creating dir "%s": %s', d, msg)
  endif
endfunction

function p (fmt, varargin)
fprintf ([fmt '\n'], varargin{:})
endfunction

function out = duration_str (t)
minutes = floor (t / 60);
seconds = t - (minutes * 60);
out = sprintf('%02d:%02.3f', minutes, seconds);
endfunction
