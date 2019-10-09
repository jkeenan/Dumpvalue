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

{
    my ($x, $y);

    my $d = Dumpvalue->new( veryCompact => '' );
    ok( $d, 'create a new Dumpvalue object: veryCompact explicitly off' );
    $d->DumpElem([1, 2, 3]);
    $x = $out->read;
    like( $x, qr/^ARRAY\([^)]+\)\n0\s+1\n1\s+2\n2\s+3/,
        "DumpElem worked as expected with veryCompact explicitly off");

    my $e = Dumpvalue->new( veryCompact => 1 );
    ok( $e, 'create a new Dumpvalue object: veryCompact on' );
    $e->DumpElem([1, 2, 3]);
    $y = $out->read;
    like( $y, qr/^0\.\.2\s+1 2 3/,
        "DumpElem worked as expected with veryCompact on");

    my $f = Dumpvalue->new( veryCompact => '' );
    $f->DumpElem({ a => 1, b => 2, c => 3 });
    $x = $out->read;
    like( $x, qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n'c'\s=>\s3/,
        "DumpElem worked as expected with veryCompact explicitly off: hashref");

    my $g = Dumpvalue->new( veryCompact => 1 );
    ok( $g, 'create a new Dumpvalue object: veryCompact on' );
    $g->DumpElem({ a => 1, b => 2, c => 3 });
    $y = $out->read;
    like( $y, qr/^'a'\s=>\s1,\s'b'\s=>\s2,\s'c'\s=>\s3/,
        "DumpElem worked as expected with veryCompact on: hashref");

    my $h = Dumpvalue->new( veryCompact => '' );
    ok( $h, 'create a new Dumpvalue object: veryCompact explicitly off' );
    $h->DumpElem([1, 2, ['a']]);
    $x = $out->read;
    like( $x, qr/^ARRAY\([^)]+\)\n0\s+1\n1\s+2\n2\s+ARRAY\([^)]+\)\n\s+0\s+'a'/,
        "DumpElem worked as expected with veryCompact explicitly off:  array contains ref");

    my $i = Dumpvalue->new( veryCompact => 1 );
    ok( $i, 'create a new Dumpvalue object: veryCompact on' );
    $i->DumpElem([1, 2, ['a']]);
    $y = $out->read;
    like( $y, qr/^ARRAY\([^)]+\)\n0\s+1\n1\s+2\n2\s+0\.\.0\s+'a'/,
        "DumpElem worked as expected with veryCompact on: array contains ref");

    my $j = Dumpvalue->new( veryCompact => '' );
    ok( $j, 'create a new Dumpvalue object: veryCompact explicitly off' );
    $j->DumpElem({ a => 1, b => 2, c => ['a'] });
    $x = $out->read;
    like( $x, qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n'c'\s=>\sARRAY\([^)]+\)\n\s+0\s+'a'/,
        "DumpElem worked as expected with veryCompact explicitly off:  hash contains ref");

    my $k = Dumpvalue->new( veryCompact => 1 );
    ok( $k, 'create a new Dumpvalue object: veryCompact on' );
    $k->DumpElem({ a => 1, b => 2, c => ['a'] });
    $y = $out->read;
    like( $y, qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n'c'\s=>\s0\.\.0\s+'a'/,
        "DumpElem worked as expected with veryCompact on:  hash contains ref");

    my $l = Dumpvalue->new( veryCompact => '', hashDepth => 2 );
    $l->DumpElem({ a => 1, b => 2, c => 3 });
    $x = $out->read;
    like( $x, qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n\.{4}/,
        "DumpElem worked as expected with veryCompact explicitly off: hashref hashdepth");

    my $m = Dumpvalue->new( veryCompact => 1, hashDepth => 2 );
    ok( $m, 'create a new Dumpvalue object: veryCompact on' );
    $m->DumpElem({ a => 1, b => 2, c => 3 });
    $y = $out->read;
    like( $y, qr/^'a'\s=>\s1,\s'b'\s=>\s2\s\.+/,
        "DumpElem worked as expected with veryCompact on: hashref hashdepth");

    my $n = Dumpvalue->new( veryCompact => '', hashDepth => 4 );
    ok( $n, 'create a new Dumpvalue object: veryCompact off' );
    $n->DumpElem({ a => 1, b => 2, c => 3 });
    $x = $out->read;
    like( $x, qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n'c'\s+=>\s+3/,
        "DumpElem worked as expected with veryCompact explicitly off: hashref hashdepth");

    my $o = Dumpvalue->new( veryCompact => 1, hashDepth => 4 );
    ok( $o, 'create a new Dumpvalue object: veryCompact on' );
    $o->DumpElem({ a => 1, b => 2, c => 3 });
    $y = $out->read;
    like( $y, qr/^'a'\s=>\s1,\s+'b'\s=>\s2,\s+'c'\s+=>\s+3/,
        "DumpElem worked as expected with veryCompact on: hashref hashdepth");

}
__END__
    print STDERR "AAA: $x\n";
    print STDERR "AAA: $y\n";

