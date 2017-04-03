#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use utf8;

use String::Random qw(random_regex);

print random_regex( $ARGV[0] );
