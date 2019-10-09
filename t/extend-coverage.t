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

{
    my $d;
    ok( $d = Dumpvalue->new(), 'create a new Dumpvalue object' );
    #is( $d->stringify(), 'undef', 'stringify handles undef okay' );
    # Need to create a "stringify-overloaded object", then test with
    # non-default value 'bareStringify = 0'.
}


{
    my ($x, $y);

    my $d = Dumpvalue->new( quoteHighBit => '', unctrl => 'quote' );
    ok( $d, 'create a new Dumpvalue object: quoteHighBit explicitly off' );
    $x = $d->stringify("\N{U+266}"); 
    is ($x, "'\N{U+266}'" , 'quoteHighBit off' ); 

    my $e = Dumpvalue->new( quoteHighBit => 1, unctrl => 'quote' );
    ok( $e, 'create a new Dumpvalue object: quoteHighBit on' );
    $y = $e->stringify("\N{U+266}"); 
    is( $y, q|'\1146'|, "quoteHighBit on");

    my $f = Dumpvalue->new( quoteHighBit => '', unctrl => 'unctrl' );
    ok( $f, 'create a new Dumpvalue object: quoteHighBit explicitly off, unctrl' );
    $x = $f->stringify("\N{U+266}"); 
    is ($x, "'\N{U+266}'" , 'quoteHighBit off' ); 

    my $g = Dumpvalue->new( quoteHighBit => '', unctrl => 'unctrl' );
    ok( $g, 'create a new Dumpvalue object: quoteHighBit explicitly off, unctrl' );
    $y = $g->stringify("\N{U+266}"); 
    is ($y, "'\N{U+266}'" , 'quoteHighBit off' ); 

    my $h = Dumpvalue->new( quoteHighBit => '', tick => '"' );
    ok( $h, 'create a new Dumpvalue object: quoteHighBit explicitly off, tick quote' );
    $x = $h->stringify("\N{U+266}"); 
    is ($x, q|"| . "\N{U+266}" . q|"| , 'quoteHighBit off' ); 

    my $i = Dumpvalue->new( quoteHighBit => 1, tick => '"' );
    ok( $i, 'create a new Dumpvalue object: quoteHighBit on, tick quote' );
    $y = $i->stringify("\N{U+266}"); 
    is( $y, q|"\1146"|, "quoteHighBit on");

}

__END__

