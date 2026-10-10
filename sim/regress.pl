#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
exec('python3', "$FindBin::Bin/regress.py", @ARGV) or die "Cannot start regression: $!\n";
