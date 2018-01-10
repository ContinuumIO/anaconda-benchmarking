#!/usr/bin/env perl
##
### Preamble {{{
##  ==========================================================================
##        @file hardening-check
##  --------------------------------------------------------------------------
##     @version 0.0.0
##  --------------------------------------------------------------------------
##     @updated 2016-06-11 Saturday 00:38:55 (+0200)
##  --------------------------------------------------------------------------
##     @created 2016-06-11 Saturday 00:38:34 (+0200)
##  --------------------------------------------------------------------------
##      @author Kees Cook <kees@debian.org>
##              --------------------------------------------------------------
##              Alexander Shukaev <http://Alexander.Shukaev.name>
##  --------------------------------------------------------------------------
##  @maintainer Alexander Shukaev <http://Alexander.Shukaev.name>
##  --------------------------------------------------------------------------
##   @copyright Copyright (C) 2013,
##              Kees Cook <kees@debian.org>.
##              All rights reserved.
##              --------------------------------------------------------------
##              Copyright (C) 2016,
##              Alexander Shukaev <http://Alexander.Shukaev.name>.
##              All rights reserved.
##  --------------------------------------------------------------------------
##     @license This program is free software; you can redistribute it and/or
##              modify it under the terms of the GNU General Public License as
##              published by the Free Software Foundation; either version 2 of
##              the License, or (at your option) any later version.
##
##              This program is distributed in the hope that it will be
##              useful, but WITHOUT ANY WARRANTY; without even the implied
##              warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
##              PURPOSE.  See the GNU General Public License for more details.
##
##              You should have received a copy of the GNU General Public
##              License along with this program.  If not, see
##              <http://www.gnu.org/licenses/>.
##  ==========================================================================
##  }}} Preamble
##
use strict;
use warnings;
##
use Cwd 'realpath';
use Getopt::Long qw(:config no_ignore_case bundling);
use IPC::Open3;
use Pod::Usage;
use Symbol qw(gensym);
use Term::ANSIColor;
##
my $no_pie     = 0;
my $no_ssp     = 0;
my $no_ffs     = 0;
my $no_sfsfs   = 0;
my $no_nes     = 0;
my $no_neh     = 0;
my $no_relro   = 0;
my $no_now     = 0;
my $report_ufs = 0;
my $find_ffs   = 0;
my $find_libc  = 0;
my $libc       = '';
my $color      = 0;
my $lintian    = 0;
my $verbose    = 0;
my $debug      = 0;
my $quiet      = 0;
my $help       = 0;
my $man        = 0;
##
pod2usage(-exitstatus => 1, -verbose => 1                 ) if (!@ARGV);
GetOptions(
  'no-pie|e+'     => \$no_pie,
  'no-ssp|p+'     => \$no_ssp,
  'no-ffs|f+'     => \$no_ffs,
  'no-sfsfs|s+'   => \$no_sfsfs,
  'no-nes|S+'     => \$no_nes,
  'no-neh|H+'     => \$no_neh,
  'no-relro|R+'   => \$no_relro,
  'no-now|N+'     => \$no_now,
  'report-ufs|U!' => \$report_ufs,
  'find-ffs|F!'   => \$find_ffs,
  'find-libc|L!'  => \$find_libc,
  'libc=s'        => \$libc,
  'color|c!'      => \$color,
  'lintian|l!'    => \$lintian,
  'debug|d!'      => \$debug,
  'quiet|q!'      => \$quiet,
  'verbose|v!'    => \$verbose,
  'help|h|?'      => \$help,
  'man|m'         => \$man,
) or pod2usage(1);
pod2usage(-exitstatus => 0, -verbose => 1                 ) if ($help);
pod2usage(-exitstatus => 0, -verbose => 2, -noperldoc => 1) if ($man);
pod2usage(-exitstatus => 1, -verbose => 1                 ) if (!@ARGV &&
                                                                !$find_ffs);
##
$libc = realpath($libc) if ($libc);
##
my $indent_level = 0;
my $indent_width = 2;
##
my $report = '';
my $status = 0;
my %tags; {
  my $ignored    = 'ignored';
  my $protected  = 'protected';
  my $vulnerable = 'vulnerable';
  ##
  $ignored    = colored($ignored,    'yellow') if ($color);
  $protected  = colored($protected,  'green')  if ($color);
  $vulnerable = colored($vulnerable, 'red')    if ($color);
  ##
  $ignored    = "[$ignored]";
  $protected  = "[$protected]";
  $vulnerable = "[$vulnerable]";
  ##
  $tags{ignored}    = $ignored;
  $tags{protected}  = $protected;
  $tags{vulnerable} = $vulnerable;
}
##
sub message {
  my ($string, $quiet) = @_;
  if (!defined $quiet) {
    $quiet = 0;
  }
  if (!$quiet) {
    $report .= ' ' x ($indent_level * $indent_width);
    $report .= "$string\n";
  }
}
##
sub success {
  my ($name, $result, $reason, $ignored) = @_;
  $result = colored($result, 'green') if ($color);
  if (!defined $ignored) {
    $ignored = 0;
  }
  if ($ignored) {
    $result .= " $tags{ignored}";
  }
  if (defined $reason && $reason) {
    $result .= " ($reason)";
  }
  message("$name: $result", $quiet);
}
##
my @lintian_tags;
##
sub failure {
  my ($tag, $file, $name, $result, $reason, $ignored) = @_;
  $result = colored($result, 'red') if ($color);
  if (!defined $ignored) {
    $ignored = 0;
  }
  if ($ignored) {
    $result .= " $tags{ignored}";
  } else {
    $status = 1;
    if ($lintian) {
      push(@lintian_tags, "$tag:$file");
    }
  }
  if (defined $reason && $reason) {
    $result .= " ($reason)";
  }
  message("$name: $result", $quiet && $ignored);
}
##
sub unknown {
  my ($name, $result, $reason) = @_;
  $result = colored($result, 'yellow') if ($color);
  if (defined $reason && $reason) {
    $result .= " ($reason)";
  }
  message("$name: $result", $quiet);
}
##
sub output(@) {
  my (@cmd) = @_;
  my ($pid, $stdout, $stderr);
  print join(' ', @cmd), "\n" if ($debug);
  $stdout = gensym;
  $stderr = gensym;
  $pid    = open3(gensym, $stdout, $stderr, @cmd);
  my $output = '';
  while ( <$stdout> ) {
    $output .= $_;
  }
  waitpid($pid, 0);
  my $status = $?;
  if ($status) {
    while ( <$stderr> ) {
      print STDERR;
    }
    return '';
  }
  return $output;
}
##
sub find_libc($) {
  my ($file) = @_;
  my $ldd = output('ldd', $file);
  if ($ldd =~ /^\s*libc\.so\.\S+\s+\S+\s+(\S+)/m) {
    message($1) if ($find_libc);
    return $1;
  }
  return '';
}
##
sub find_functions($$) {
  my ($file, $undefined) = @_;
  my (%functions);
  # Include 'NOTYPE' for object archives:
  my $re      = ' (I?FUNC|NOTYPE) ';
  my $symbols = output('readelf', '-sW', $file);
  for my $line (split("\n", $symbols)) {
    next if ($line !~ /$re/);
    next if ($undefined && $line !~ /$re.*\s+UND\s+/);
    $line =~ s/\s+\(\d+\)$//;
    $line =~ s/.*\s+//;
    $line =~ s/@.*//;
    $functions{$line} = 1 if ($line);
  }
  return \%functions;
}
##
sub find_fortified_functions($) {
  my ($file) = @_;
  my (%fortified_functions);
  my $functions = find_functions($file, 0);
  for my $function (sort(keys(%$functions))) {
    if ($function =~ /^__(\S+)_chk$/) {
      message($1) if ($find_ffs);
      $fortified_functions{$1} = 1;
    }
  }
  return \%fortified_functions;
}
##
sub find_undefined_functions($) {
  my ($file) = @_;
  return find_functions($file, 1);
}
##
$ENV{'LANG'} = 'C';
##
if (($find_ffs && !$libc) || $find_libc) {
  pod2usage(1) if (!defined($ARGV[0]));
  $libc = find_libc($ARGV[0]);
}
##
my $libc_ffs = $libc ? find_fortified_functions($libc) : {};
##
if ($find_ffs || $find_libc) {
  print $report;
  exit($status);
}
##
my $cache = {
  libc     => '',
  libc_ffs => {},
};
##
sub report($) {
  my ($file) = @_;
  {
    $indent_level = 1;
    $report       = "$file:\n";
    $status       = 0;
    @lintian_tags = ();
  }
  my $program_headers = output('readelf', '-lW', $file);
  return 1 if (!$program_headers);
  my $dynamic_section = output('readelf', '-dW', $file);
  my $elf             = 1;
  my $ffs             = \%$libc_ffs;
  my $ufs             = find_undefined_functions($file);
  ##
  # Position Independent Executable (PIE)
  # =====================================
  ##
  {
    my $name = "Position Independent Executable (PIE)";
    $program_headers =~ /^Elf file type is (\S+)/m;
    my $elf_type = $1 || '';
    if ($elf_type eq 'DYN') {
      if ($program_headers =~ /^\s*\bPHDR\b/m) {
        success($name, 'yes');
      } else {
        success($name, 'no', "shared library", 1);
      }
    } elsif ($elf_type eq 'EXEC') {
      failure('no-pie', $file,
              $name, 'no', "regular executable", $no_pie);
    } else {
      $elf = 0;
      open(AR, "<$file");
      my $header = <AR>;
      close(AR);
      if ($header eq "!<arch>\n") {
        success($name, 'no', "object archive", 1);
      } else {
        success($name, 'no', "unknown ELF type: $elf_type", 1);
      }
    }
  }
  ##
  # Stack Smashing Protector (SSP)
  # ==============================
  ##
  {
    my $name = "Stack Smashing Protector (SSP)";
    if (defined($ufs->{'__stack_chk_fail'}) ||
        (!$elf && defined($ufs->{'__stack_chk_fail_local'}))) {
      success($name, 'yes');
    } else {
      failure('no-stackprotector', $file,
              $name, 'no', "not found", $no_ssp);
    }
  }
  ##
  # Fortified Functions (FFs)
  # =========================
  ##
  if ($elf) {
    my $path = find_libc($file);
    if ($path) {
      $path = realpath($path);
      if ($path eq $cache->{libc}) {
        $ffs = $cache->{libc_ffs};
      } elsif ($path ne $libc) {
        $ffs = find_fortified_functions($path);
        $cache->{libc}     = $path;
        $cache->{libc_ffs} = $ffs;
      }
    }
  }
  {
    my $name   = "Fortified Functions (FFs)";
    my $failed = 0;
    my @vfs;
    my @pfs;
    for my $function (keys(%$ffs)) {
      push(@vfs, $function) if (defined($ufs->{$function}));
      push(@pfs, $function) if (defined($ufs->{"__${function}_chk"}));
    }
    if ($#pfs > -1) {
      if ($#vfs == -1) {
        success($name, 'yes');
      } else {
        # Vague, due to possible compile-time optimization, multiple linkages,
        # etc.  Assume 'yes' for now:
        success($name, 'yes', "some protected functions found");
      }
    } else {
      if ($#vfs == -1) {
        unknown($name, 'unknown', "no protected functions found");
      } else {
        # Vague, since it's possible to have compile-time optimizations undo
        # them or be otherwise unverifiable at run time.  Assume 'no' for now:
        failure('no-fortify-functions', $file,
                $name, 'no', "only vulnerable functions found", $no_ffs);
        $failed = 1;
      }
    }
    if ($verbose && ($failed || !$quiet)) {
      $indent_level++;
      message("$tags{vulnerable}:") if ($#vfs > -1);
      $indent_level++;
      for my $function (sort(@vfs)) {
        message($function);
      }
      $indent_level--;
      message("$tags{protected}:") if ($#pfs > -1);
      $indent_level++;
      for my $function (sort(@pfs)) {
        message($function);
      }
      $indent_level--;
      $indent_level--;
    }
  }
  ##
  # String Format Security Functions (SFSFs)
  # ========================================
  #
  # Unfortunately, I haven't thought of a way to test for this after
  # compilation.  What it really needs is a lintian-like check that reviews
  # the build logs and looks for the warnings or that the argument is changed
  # to use '-Werror=format-security' to stop the build.
  ##
  {
    my $name = "String Format Security Functions (SFSFs)";
    unknown($name, 'unknown', "not supported");
  }
  ##
  # Non-Executable Stack (NES)
  # ==========================
  ##
  {
    my $name = "Non-Executable Stack (NES)";
    if ($elf) {
      if ($program_headers =~
          /^\s*\bGNU_STACK\b\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)/m) {
        if ($1 =~ /^.*E.*$/) {
          failure('no-noexecstack', $file,
                  $name, 'no', "not found", $no_nes);
        } else {
          success($name, 'yes');
        }
      } else {
        failure('no-noexecstack', $file,
                $name, 'no', "not found", $no_nes);
      }
    } else {
      my $section_headers = output('readelf', '-SW', $file);
      my $type            = '.note.GNU-stack';
      my @objects         = ();
      my $counter         = 0;
      for my $line (split("\n", $section_headers)) {
        if ($line =~ /^\s*File:.*\((.*)\)/) {
          push(@objects, $1);
          next;
        }
        if ($line =~
            /^\s*\[.+\]\s*\Q$type\E\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)/) {
          if ($1 !~ /^.*X.*$/) {
            $counter++;
            pop(@objects) if (@objects);
          }
        }
      }
      if (!@objects && $counter) {
        success($name, 'yes');
      } else {
        failure('no-noexecstack', $file,
                $name, 'no', "not found", $no_nes);
      }
      if ($verbose) {
        $indent_level++;
        for my $object (sort(@objects)) {
          message($object);
        }
        $indent_level--;
      }
    }
  }
  ##
  # Non-Executable Heap (NEH)
  # =========================
  ##
  {
    my $name = "Non-Executable Heap (NEH)";
    if ($elf) {
      if ($program_headers =~
          /^\s*\bGNU_HEAP\b\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)/m) {
        if ($1 =~ /^.*E.*$/) {
          failure('no-noexecheap', $file,
                  $name, 'no', "not found", $no_neh);
        } else {
          success($name, 'yes');
        }
      } else {
        failure('no-noexecheap', $file,
                $name, 'no', "not found", $no_neh);
      }
    } else {
      my $section_headers = output('readelf', '-SW', $file);
      my $type            = '.note.GNU-heap';
      my @objects         = ();
      my $counter         = 0;
      for my $line (split("\n", $section_headers)) {
        if ($line =~ /^\s*File:.*\((.*)\)/) {
          push(@objects, $1);
          next;
        }
        if ($line =~
            /^\s*\[.+\]\s*\Q$type\E\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)/) {
          if ($1 !~ /^.*X.*$/) {
            $counter++;
            pop(@objects) if (@objects);
          }
        }
      }
      if (!@objects && $counter) {
        success($name, 'yes');
      } else {
        failure('no-noexecheap', $file,
                $name, 'no', "not found", $no_neh);
      }
      if ($verbose) {
        $indent_level++;
        for my $object (sort(@objects)) {
          message($object);
        }
        $indent_level--;
      }
    }
  }
  ##
  # Relocation Read-Only (RELRO)
  # ============================
  ##
  {
    my $name = "Relocation Read-Only (RELRO)";
    if ($program_headers =~ /^\s*\bGNU_RELRO\b/m) {
      success($name, 'yes');
    } else {
      if ($elf) {
        failure('no-relro', $file,
                $name, 'no', "not found", $no_relro);
      } else {
        success($name, 'no', "not ELF", 1);
      }
    }
  }
  ##
  # Immediate Symbol Binding (NOW)
  # ==============================
  #
  # This marking keeps changing:
  #
  #   0x0000000000000018 (BIND_NOW)
  #   0x000000006ffffffb (FLAGS)    Flags: BIND_NOW
  #   0x000000006ffffffb (FLAGS_1)  Flags: NOW
  ##
  {
    my $name = "Immediate Symbol Binding (NOW)";
    if ($dynamic_section =~ /^\s*\S+\s+\(BIND_NOW\)/m ||
        $dynamic_section =~ /^\s*\S+\s+\(FLAGS\).*\bBIND_NOW\b/m ||
        $dynamic_section =~ /^\s*\S+\s+\(FLAGS_1\).*\bNOW\b/m) {
      success($name, 'yes');
    } else {
      if ($elf) {
        failure('no-bindnow', $file,
                $name, 'no', "not found", $no_now);
      } else {
        success($name, 'no', "not ELF", 1);
      }
    }
  }
  ##
  if ($lintian) {
    for my $tag (sort(@lintian_tags)) {
      print $tag, "\n";
    }
    return 0;
  } else {
    print $report if (!$quiet || $status);
    ##
    # Undefined Functions (UFs)
    # =========================
    ##
    if ($report_ufs && scalar(keys(%$ufs)) > 0) {
      $report = '';
      message('Undefined Functions (UFs):');
      $indent_level++;
      for my $function (sort(keys(%$ufs))) {
        message($function);
      }
      $indent_level--;
      print $report;
    }
  }
  return $status;
}
##
foreach my $file (@ARGV) {
  my $s = report($file);
  $status = $s if ($s);
}
##
exit($status);
##
__END__

=pod

=head1 NAME

hardening-check - check ELF binaries for security hardening features

=head1 SYNOPSIS

hardening-check [options] [ELF ...]

Examine a given list of ELF binaries and check for several security hardening
features, failing if they are not all found.

=head1 DESCRIPTION

This utility checks a given list of ELF binaries for several security
hardening features that could have been built into them.  These features are:

=over 2

=item B<Position Independent Executable (PIE)>

This indicates that a given ELF executable was built in such a way that the
"text" section of the program can be relocated in memory.  To take full
advantage of this feature, the executing kernel must support text Address
Space Layout Randomization (ASLR).

=item B<Stack Smashing Protector (SSP)>

This indicates that a given ELF binary was compiled with the L<gcc(1)> option
B<-fstack-protector> and/or B<-fstack-protector-strong> (e.g. uses either
B<__stack_chk_fail> or B<__stack_chk_fail_local>).  That is the program will
be resistant to having its stack buffers accidentally overflowed and/or
deliberately smashed (for example, due to attack).

CAUTION:

When a given ELF binary was built without any character arrays actually being
allocated on stack, this check will lead to false alarms (since there is no
use of B<__stack_chk_fail> or B<__stack_chk_fail_local>), even though it was
compiled with the correct options.

=item B<Fortified Functions (FFs)>

This indicates that a given ELF binary was compiled with
B<-D_FORTIFY_SOURCE=2> and the L<gcc(1)> optimization option B<-O1> or higher.
This either substitutes certain vulnerable B<libc> functions with their
protected counterparts (e.g. B<strncpy> instead of B<strcpy>) or replaces
calls that are verifiable at run time with the run-time-check version
(e.g. B<__memcpy_chk> instead of B<memcpy>).

CAUTION:

When a given ELF binary was built such that the fortified versions of the
B<libc> functions are not useful (e.g. use is verified as safe at compile time
or use cannot be verified at run time), this check will lead to false alarms.
In an effort to mitigate this misbehavior, the check will pass if any
fortified function is found, and will fail if only unfortified functions are
found.  Not verifiable conditions also pass (e.g. no functions that could have
been fortified are found or not linked against B<libc> at all).

=item B<String Format Security Functions (SFSFs)>

This indicates that a given ELF binary was compiled with the L<gcc(1)> option
B<-Wformat=2>.

=item B<Non-Executable Stack (NES)>

This indicates that a given ELF binary was linked with the L<gcc(1)> option
B<-Wl,-z,noexecstack> (see L<ld(1)>) to have special ELF markings
(i.e. B<GNU_STACK>) that cause the dynamic linker/loader L<ld.so(8)> to mark
any stack memory regions as non-executable.  This reduces the amount of
vulnerable memory regions in a program that could be potentially exposed to
memory corruption attacks.

=item B<Non-Executable Heap (NEH)>

This indicates that a given ELF binary was linked with the L<gcc(1)> option
B<-Wl,-z,noexecheap> (see L<ld(1)>) to have special ELF markings
(i.e. B<GNU_HEAP>) that cause the dynamic linker/loader L<ld.so(8)> to mark
any heap memory regions as non-executable.  This reduces the amount of
vulnerable memory regions in a program that could be potentially exposed to
memory corruption attacks.

=item B<Relocation Read-Only (RELRO)>

This indicates that a given ELF binary was linked with the L<gcc(1)> option
B<-Wl,-z,relro> (see L<ld(1)>) to have special ELF markings (i.e. B<RELRO>)
that cause the dynamic linker/loader L<ld.so(8)> to mark any regions of the
relocation table as read-only if they were resolved before the actual
execution begins.  This reduces the amount of vulnerable memory regions in a
program that could be potentially exposed to memory corruption attacks.

=item B<Immediate Symbol Binding (NOW)>

This indicates that a given ELF binary was linked with the L<gcc(1)> option
B<-Wl,-z,now (see L<ld(1)>)> to have special ELF markings (e.g. B<BIND_NOW> or
B<NOW>) that cause the dynamic linker/loader L<ld.so(8)> to resolve all
symbols before the actual execution begins.  When combined with RELRO (see
above), this further reduces the amount of vulnerable memory regions in a
program that could be potentially exposed to memory corruption attacks.

=back

=head1 OPTIONS

=over 2

=item B<--no-pie>, B<-e>

Do not require that the checked ELF binaries are built as PIE.

=item B<--no-ssp>, B<-p>

Do not require that the checked ELF binaries are compiled with SSP.

=item B<--no-ffs>, B<-f>

Do not require that the checked ELF binaries are compiled with FFs.

=item B<--no-sfsfs>, B<-s>

Do not require that the checked ELF binaries are compiled with SFSFs.

=item B<--no-nes>, B<-S>

Do not require that the checked ELF binaries are linked with NES.

=item B<--no-neh>, B<-H>

Do not require that the checked ELF binaries are linked with NEH.

=item B<--no-relro>, B<-R>

Do not require that the checked ELF binaries are linked with RELRO.

=item B<--no-now>, B<-N>

Do not require that the checked ELF binaries are linked with NOW.

=item B<--report-ufs>, B<-U>

Additionally, report all undefined (external) functions needed by the checked
ELF binaries.

=item B<--find-ffs>, B<-F>

Instead of the regular report, find B<libc> for the first given ELF binary and
report all fortified functions exported by this B<libc>.

=item B<--find-libc>, B<-L>

Instead of the regular report, find B<libc> for the first given ELF binary and
report the absolute path to this B<libc>.

=item B<--libc>

Explicitly specify the path to B<libc> that is to be searched for exported
fortified functions at least for checks on object archives and object files.

=item B<--color>, B<-c>

Colorize report with ANSI escape sequences.

=item B<--lintian>, B<-l>

Report in Lintian (Debian) format.

=item B<--debug>, B<-d>

Report debug information.

=item B<--quiet>, B<-q>

Report only (not ignored) failures.

=item B<--verbose>, B<-v>

Report verbosely on failures.

=item B<--help>, B<-h>, B<-?>

Print a brief help message and exit.

=item B<--man>, B<-m>

Print a detailed manual page and exit.

=back

=head1 RETURN VALUE

When all the checked ELF binaries support all the specified security hardening
features, this program will finish with the exit status of 0.  Otherwise, if
any check fails, the exit status will be 1.  Each individual check can be
disabled via a corresponding command line option.

=head1 AUTHOR

=over 2

=item Kees Cook <kees@debian.org>

=item Alexander Shukaev L<http://Alexander.Shukaev.name>.

=back

=head1 MAINTAINER

=over 2

=item Alexander Shukaev L<http://Alexander.Shukaev.name>.

=back

=head1 COPYRIGHT

=over 2

=item Copyright (C) 2013,
      Kees Cook <kees@debian.org>.
      All rights reserved.

=item Copyright (C) 2016,
      Alexander Shukaev L<http://Alexander.Shukaev.name>.
      All rights reserved.

=back

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see L<http://www.gnu.org/licenses/>.

=head1 SEE ALSO

L<hardening-wrapper(1)>, L<gcc(1)>, L<ld(1)>, L<ld.so(8)>

=head1 REFERENCES

=over 2

=item S<[ 1] >L<http://blog.siphos.be/2011/07/high-level-explanation-on-some-binary-executable-security>

=item S<[ 2] >L<http://en.chys.info/2010/12/note-gnu-stack>

=item S<[ 3] >L<http://grantcurell.com/2015/09/21/what-is-the-symbol-table-and-what-is-the-global-offset-table>

=item S<[ 4] >L<http://infocenter.arm.com/help/index.jsp?topic=/com.arm.doc.faqs/ka14320.html>

=item S<[ 5] >L<http://lintian.debian.org/tags-all.html>

=item S<[ 6] >L<http://tk-blog.blogspot.de/2009/02/relro-not-so-well-known-memory.html>

=item S<[ 7] >L<http://wiki.debian.org/Hardening>

=item S<[ 8] >L<http://wiki.gentoo.org/wiki/Hardened/GNU_stack_quickstart>

=item S<[ 9] >L<http://wiki.gentoo.org/wiki/Hardened/Toolchain>

=item S<[10] >L<http://wiki.osdev.org/Stack_Smashing_Protector>

=item S<[11] >L<http://wiki.ubuntu.com/SecurityTeam/Roadmap/ExecutableStacks>

=item S<[12] >L<http://wikipedia.org/wiki/Address_space_layout_randomization>

=item S<[13] >L<http://wikipedia.org/wiki/Buffer_overflow>

=item S<[14] >L<http://wikipedia.org/wiki/Buffer_overflow_protection>

=item S<[15] >L<http://wikipedia.org/wiki/Return-oriented_programming>

=item S<[16] >L<http://wikipedia.org/wiki/Stack_buffer_overflow>

=item S<[17] >L<http://wikipedia.org/wiki/Uncontrolled_format_string>

=item S<[18] >L<http://www.owasp.org/index.php/C-Based_Toolchain_Hardening>

=item S<[19] >L<http://www.win.tue.nl/~aeb/linux/hh/protection.html>

=back

=cut
