BEGIN {
    require Config;
    if (($Config::Config{'extensions'} !~ m!\bList/Util\b!) ){
        print "1..0 # Skip -- Perl configured without List::Util module\n";
        exit 0;
    }

    # `make test` in the CPAN version of this module runs us with -w, but
    # Dumpvalue.pm relies on all sorts of things that can cause warnings. I
    # don't think that's worth fixing, so we just turn off all warnings
    # during testing.
    $^W = 0;
}

use lib ("./t/lib");
use TieOut;
use Test::More qw(no_plan); # tests => 17;

use_ok( 'Dumpvalue' );

my $out = tie *OUT, 'TieOut';
select(OUT);

{
    my $d;
    ok( $d = Dumpvalue->new(), 'create a new Dumpvalue object' );
    is( $d->get('globPrint'), 0, 'get a single (default) option correctly' );
    my @attributes = (qw|globPrint printUndef tick unctrl|);
    my @rv = $d->get(@attributes);
    my $expected = [ 0, 1, "auto", 'quote' ];
    is_deeply( \@rv, $expected, "get multiple (default) options correctly" );
}

{
    my $d;
    ok( $d = Dumpvalue->new(), 'create a new Dumpvalue object' );
    my @foobar = ('foo', 'bar');
    my @bazlow = ('baz', 'low');
    {
        local $@;
        eval { $d->dumpValue([@foobar], [@bazlow]); };
        like $@, qr/^usage: \$dumper->dumpValue\(value\)/,
            "dumpValue() takes only 1 argument";
    }
}

    

__END__

        globPrint          => 0,
        printUndef          => 1,
        tick              => "auto",
        unctrl              => 'quote',
my (@foobar, $x, $y);

@foobar = ('foo', 'bar');
$d->dumpValue([@foobar]);
$x = $out->read;
is( $x, "0  'foo'\n1  'bar'\n", 'dumpValue worked on array ref' );
$d->dumpValues(@foobar);
$y = $out->read;
is( $y, "0  'foo'\n1  'bar'\n", 'dumpValues worked on array' );
is( $y, $x,
    "dumpValues called on array returns same as dumpValue on array ref");

@foobar = (undef, 'bar');
$d->dumpValue([@foobar]);
$x = $out->read;
is( $x, "0  undef\n1  'bar'\n",
    'dumpValue worked on array ref, first element undefined' );
$d->dumpValues(@foobar);
$y = $out->read;
is( $y, "0  undef\n1  'bar'\n",
    'dumpValues worked on array, first element undefined' );
is( $y, $x,
    "dumpValues called on array returns same as dumpValue on array ref, first element undefined");

@foobar = ('bar', undef);
$d->dumpValue([@foobar]);
$x = $out->read;
is( $x, "0  'bar'\n1  undef\n",
    'dumpValue worked on array ref, last element undefined' );
$d->dumpValues(@foobar);
$y = $out->read;
is( $y, "0  'bar'\n1  undef\n",
    'dumpValues worked on array, last element undefined' );
is( $y, $x,
    "dumpValues called on array returns same as dumpValue on array ref, last element undefined");

@foobar = ('', 'bar');
$d->dumpValue([@foobar]);
$x = $out->read;
is( $x, "0  ''\n1  'bar'\n",
    'dumpValue worked on array ref, first element empty string' );
$d->dumpValues(@foobar);
$y = $out->read;
is( $y, "0  ''\n1  'bar'\n",
    'dumpValues worked on array, first element empty string' );
is( $y, $x,
    "dumpValues called on array returns same as dumpValue on array ref, first element empty string");

@foobar = ('bar', '');
$d->dumpValue([@foobar]);
$x = $out->read;
is( $x, "0  'bar'\n1  ''\n",
    'dumpValue worked on array ref, last element empty string' );
$d->dumpValues(@foobar);
$y = $out->read;
is( $y, "0  'bar'\n1  ''\n",
    'dumpValues worked on array, last element empty string' );
is( $y, $x,
    "dumpValues called on array returns same as dumpValue on array ref, last element empty string");

