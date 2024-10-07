package App::Greple::index;

use 5.024;
use warnings;

our $VERSION = "0.01";

=encoding utf-8

=head1 NAME

App::Greple::index - Greple index manipulation module

=head1 SYNOPSIS

    greple -Mindex ...

=head1 DESCRIPTION

App::Greple::index is a module for B<greple> to manipulate
pattern match index.

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use List::Util qw(max);
use Hash::Util qw(lock_keys);

our %opt = (
    debug => \(our $debug = 0),
    step  => \(our $step = 2),
);
lock_keys %opt;
sub opt :lvalue { ${$opt{+shift}} }

my @series = (
    [ qw(/544 /533) ],
    [ qw(/454 /353) ],
    [ qw(/445 /335) ],
    [ qw(/554 /553) ],
    [ qw(/545 /535) ],
    [ qw(/554 /553) ],
);

sub finalize {
    our($mod, $argv) = @_;
    my @default = qw(--index-postgrep);
    for my $i (0, 1) {
	for my $s (0 .. $step - 1) {
	    push @default, "--cm $series[$s % @series]->[$i]";
	}
    }
    $mod->setopt(default => join(' ', @default));
}

#
# Increment each index by $step
#
sub stripe_index {
    my $grep = shift;
    if ($step == 0) {
	$step = _max_index($grep) + 1;
    }
    my @counter = (-$step .. -1);
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	for my $m (@match) {
	    my $mod = $m->[2] % $step;
	    $m->[2] = ($counter[$mod] += $step);
	}
    }
}

sub _max_index {
    my $grep = shift;
    my $max = 0;
    for my $r ($grep->result) {
	my($b, @match) = @$r;
	$max = max($max, map($_->[2], @match));
    }
}

sub set {
    while (my($key, $val) = splice @_, 0, 2) {
	next if $key eq &::FILELABEL;
	die "$key: Invalid option.\n" if not exists $opt{$key};
	opt($key) = $val;
    }
}

1;

__DATA__

builtin index-debug! $debug
builtin index-step:i $step

option --index-postgrep \
	 --postgrep &__PACKAGE__::stripe_index

option --index-series-2 \
	--cm=/544,/454 \
	--cm=/533,/353

option --index-series-3 \
	--cm=/544,/454,/445 \
	--cm=/533,/353,/335
