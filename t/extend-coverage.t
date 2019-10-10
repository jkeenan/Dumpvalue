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
use List::Util qw( sum );
use File::Temp qw( tempfile tempdir );
use File::Spec;

use_ok( 'Dumpvalue' );

my $out = tie *OUT, 'TieOut';
select(OUT);

{
    my $d = Dumpvalue->new();
    ok( $d, 'create a new Dumpvalue object' );
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
    my (@x, @y);

    my $d = Dumpvalue->new( quoteHighBit => '', unctrl => 'quote' );
    ok( $d, 'create a new Dumpvalue object: quoteHighBit explicitly off' );
    $x[0] = $d->stringify("\N{U+266}");
    is ($x[0], "'\N{U+266}'" , 'quoteHighBit off' );

    my $e = Dumpvalue->new( quoteHighBit => 1, unctrl => 'quote' );
    ok( $e, 'create a new Dumpvalue object: quoteHighBit on' );
    $y[0] = $e->stringify("\N{U+266}");
    is( $y[0], q|'\1146'|, "quoteHighBit on");

    my $f = Dumpvalue->new( quoteHighBit => '', unctrl => 'unctrl' );
    ok( $f, 'create a new Dumpvalue object: quoteHighBit explicitly off, unctrl' );
    $x[1] = $f->stringify("\N{U+266}");
    is ($x[1], "'\N{U+266}'" , 'quoteHighBit off' );

    my $g = Dumpvalue->new( quoteHighBit => '', unctrl => 'unctrl' );
    ok( $g, 'create a new Dumpvalue object: quoteHighBit explicitly off, unctrl' );
    $y[1] = $g->stringify("\N{U+266}");
    is ($y[1], "'\N{U+266}'" , 'quoteHighBit off' );

    my $h = Dumpvalue->new( quoteHighBit => '', tick => '"' );
    ok( $h, 'create a new Dumpvalue object: quoteHighBit explicitly off, tick quote' );
    $x[2] = $h->stringify("\N{U+266}");
    is ($x[2], q|"| . "\N{U+266}" . q|"| , 'quoteHighBit off' );

    my $i = Dumpvalue->new( quoteHighBit => 1, tick => '"' );
    ok( $i, 'create a new Dumpvalue object: quoteHighBit on, tick quote' );
    $y[2] = $i->stringify("\N{U+266}");
    is( $y[2], q|"\1146"|, "quoteHighBit on");
}

{
    my (@x, @y);

    my $d = Dumpvalue->new( veryCompact => '' );
    ok( $d, 'create a new Dumpvalue object: veryCompact explicitly off' );
    $d->DumpElem([1, 2, 3]);
    $x[0] = $out->read;
    like( $x[0], qr/^ARRAY\([^)]+\)\n0\s+1\n1\s+2\n2\s+3/,
        "DumpElem worked as expected with veryCompact explicitly off");

    my $e = Dumpvalue->new( veryCompact => 1 );
    ok( $e, 'create a new Dumpvalue object: veryCompact on' );
    $e->DumpElem([1, 2, 3]);
    $y[0] = $out->read;
    like( $y[0], qr/^0\.\.2\s+1 2 3/,
        "DumpElem worked as expected with veryCompact on");

    my $f = Dumpvalue->new( veryCompact => '' );
    $f->DumpElem({ a => 1, b => 2, c => 3 });
    $x[1] = $out->read;
    like( $x[1], qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n'c'\s=>\s3/,
        "DumpElem worked as expected with veryCompact explicitly off: hashref");

    my $g = Dumpvalue->new( veryCompact => 1 );
    ok( $g, 'create a new Dumpvalue object: veryCompact on' );
    $g->DumpElem({ a => 1, b => 2, c => 3 });
    $y[1] = $out->read;
    like( $y[1], qr/^'a'\s=>\s1,\s'b'\s=>\s2,\s'c'\s=>\s3/,
        "DumpElem worked as expected with veryCompact on: hashref");

    my $h = Dumpvalue->new( veryCompact => '' );
    ok( $h, 'create a new Dumpvalue object: veryCompact explicitly off' );
    $h->DumpElem([1, 2, ['a']]);
    $x[2] = $out->read;
    like( $x[2], qr/^ARRAY\([^)]+\)\n0\s+1\n1\s+2\n2\s+ARRAY\([^)]+\)\n\s+0\s+'a'/,
        "DumpElem worked as expected with veryCompact explicitly off:  array contains ref");

    my $i = Dumpvalue->new( veryCompact => 1 );
    ok( $i, 'create a new Dumpvalue object: veryCompact on' );
    $i->DumpElem([1, 2, ['a']]);
    $y[2] = $out->read;
    like( $y[2], qr/^ARRAY\([^)]+\)\n0\s+1\n1\s+2\n2\s+0\.\.0\s+'a'/,
        "DumpElem worked as expected with veryCompact on: array contains ref");

    my $j = Dumpvalue->new( veryCompact => '', dumpReused => 1 );
    ok( $j, 'create a new Dumpvalue object: veryCompact explicitly off' );
    $j->DumpElem({ a => 1, b => 2, c => ['a'] });
    $x[3] = $out->read;
    like( $x[3], qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n'c'\s=>\sARRAY\([^)]+\)\n\s+0\s+'a'/,
        "DumpElem worked as expected with veryCompact explicitly off:  hash contains ref");

    my $k = Dumpvalue->new( veryCompact => 1, dumpReused => 1  );
    ok( $k, 'create a new Dumpvalue object: veryCompact on' );
    $k->DumpElem({ a => 1, b => 2, c => ['a'] });
    $y[3] = $out->read;
    like( $y[3], qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n'c'\s=>\s0\.\.0\s+'a'/,
        "DumpElem worked as expected with veryCompact on:  hash contains ref");

    my $l = Dumpvalue->new( veryCompact => '', hashDepth => 2 );
    $l->DumpElem({ a => 1, b => 2, c => 3 });
    $x[4] = $out->read;
    like( $x[4], qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n\.{4}/,
        "DumpElem worked as expected with veryCompact explicitly off: hashref hashdepth");

    my $m = Dumpvalue->new( veryCompact => 1, hashDepth => 2 );
    ok( $m, 'create a new Dumpvalue object: veryCompact on' );
    $m->DumpElem({ a => 1, b => 2, c => 3 });
    $y[4] = $out->read;
    like( $y[4], qr/^'a'\s=>\s1,\s'b'\s=>\s2\s\.+/,
        "DumpElem worked as expected with veryCompact on: hashref hashdepth");

    my $n = Dumpvalue->new( veryCompact => '', hashDepth => 4 );
    ok( $n, 'create a new Dumpvalue object: veryCompact off' );
    $n->DumpElem({ a => 1, b => 2, c => 3 });
    $x[5] = $out->read;
    like( $x[5], qr/^HASH\([^)]+\)\n'a'\s=>\s1\n'b'\s=>\s2\n'c'\s+=>\s+3/,
        "DumpElem worked as expected with veryCompact explicitly off: hashref hashdepth");

    my $o = Dumpvalue->new( veryCompact => 1, hashDepth => 4 );
    ok( $o, 'create a new Dumpvalue object: veryCompact on' );
    $o->DumpElem({ a => 1, b => 2, c => 3 });
    $y[5] = $out->read;
    like( $y[5], qr/^'a'\s=>\s1,\s+'b'\s=>\s2,\s+'c'\s+=>\s+3/,
        "DumpElem worked as expected with veryCompact on: hashref hashdepth");
}

{
    my (@x, @y);

    my $five = '12345';
    my $six = '123456';
    my $alt = '78901';
    my @arr = ($six, $alt);
    my %two = (first => $six, notthefirst => $alt);

    my $d = Dumpvalue->new( usageOnly => '' );
    ok( $d, 'create a new Dumpvalue object: usageOnly explicitly off' );
    $x[0] = $d->scalarUsage($five);
    is( $x[0], length($five), 'scalarUsage reports length correctly' );

    my $e = Dumpvalue->new( usageOnly => 1 );
    ok( $e, 'create a new Dumpvalue object: usageOnly on' );
    $y[0] = $e->scalarUsage($five);
    is( $y[0], length($five), 'scalarUsage reports length correctly' );

    my $f = Dumpvalue->new( usageOnly => '' );
    ok( $f, 'create a new Dumpvalue object: usageOnly explicitly off' );
    $x[1] = $f->scalarUsage($six, '7890');
    is ($x[1], length($six), 'scalarUsage reports length of first element correctly' );

    my $g = Dumpvalue->new( usageOnly => 1 );
    ok( $g, 'create a new Dumpvalue object: usageOnly on' );
    $y[1] = $g->scalarUsage($six, '7890');
    is ($y[1], length($six), 'scalarUsage reports length of first element correctly' );

    my $h = Dumpvalue->new( usageOnly => '' );
    ok( $h, 'create a new Dumpvalue object: usageOnly explicitly off' );
    $x[2] = $h->scalarUsage( [ @arr ] );
    is ($x[2], sum( map { length($_) } @arr ),
        'scalarUsage reports sum of length of array elements correctly' );

    my $i = Dumpvalue->new( usageOnly => 1 );
    ok( $i, 'create a new Dumpvalue object: usageOnly on' );
    $y[2] = $i->scalarUsage( [ @arr ] );
    is ($y[2], sum( map { length($_) } @arr ),
        'scalarUsage reports length of first element correctly' );

    my $j = Dumpvalue->new( usageOnly => '' );
    ok( $j, 'create a new Dumpvalue object: usageOnly explicitly off' );
    $x[3] = $j->scalarUsage( { %two } );
    is ($x[3], sum( ( map { length($_) } keys %two ), ( map { length($_) } values %two ), ),
        'scalarUsage reports sum of length of hash keys and values correctly' );

    my $k = Dumpvalue->new( usageOnly => 1 );
    ok( $k, 'create a new Dumpvalue object: usageOnly on' );
    $y[3] = $k->scalarUsage( { %two } );
    is ($y[3], sum( ( map { length($_) } keys %two ), ( map { length($_) } values %two ), ),
        'scalarUsage reports sum of length of hash keys and values correctly' );
}

#{
#
#    use warnings;
#    my (@x, @y);
#
#    my $d = Dumpvalue->new();
#    ok( $d, 'create a new Dumpvalue object' );
#    #$x[0] = $d->dumpvars( 'main' );
#    $d->dumpvars( 'main' );
#    #print STDERR "AAA: $x[0]\n";
#
#}

{
    my (@x, @y);

    my $d = Dumpvalue->new( compactDump => 1 );
    ok( $d, 'create a new Dumpvalue object, compactDump' );
    $d->unwrap([]);
    $x[0] = $out->read;
    like( $x[0], qr/\s*empty array\n/, "unwrap() reported empty array");

    my $e = Dumpvalue->new( compactDump => 0 );
    ok( $e, 'create a new Dumpvalue object, compactDump explicitly off' );
    $e->unwrap([ qw| alpha beta gamma | ]);
    $y[0] = $out->read;
    like( $y[0], qr/0\s+'alpha'\n1\s+'beta'\n2\s+'gamma'/,
        "unwrap() with compactDump explicitly off");

    my $f = Dumpvalue->new();
    ok( $f, 'create a new Dumpvalue object' );
    $f->veryCompact(0);
    $f->unwrap([ qw| alpha beta gamma | ]);
    $x[1] = $out->read;
    like( $x[1], qr/0\s+'alpha'\n1\s+'beta'\n2\s+'gamma'/,
        "unwrap() after veryCompact method call with arg 0");

    my $g = Dumpvalue->new();
    ok( $g, 'create a new Dumpvalue object' );
    $g->veryCompact();
    $g->unwrap([ qw| alpha beta gamma | ]);
    $y[1] = $out->read;
    like( $y[1], qr/0\s+'alpha'\n1\s+'beta'\n2\s+'gamma'/,
        "unwrap() after veryCompact method call with explicitly off");

    my $h = Dumpvalue->new();
    ok( $h, 'create a new Dumpvalue object' );
    $h->compactDump(1);
    $h->veryCompact(0);
    $h->unwrap([ qw| alpha beta gamma | ]);
    $x[2] = $out->read;
    like( $x[2], qr/0\.\.2\s+'alpha'\s+'beta'\s+'gamma'/,
        "unwrap() after compactDump(1) and veryCompact(0) method calls");

    my $i = Dumpvalue->new();
    ok( $i, 'create a new Dumpvalue object' );
    $i->compactDump(0);
    $i->unwrap([ qw| alpha beta gamma | ]);
    $y[2] = $out->read;
    like( $y[1], qr/0\s+'alpha'\n1\s+'beta'\n2\s+'gamma'/,
        "unwrap() after compactDump(0) method call");

}

{
    my (@x, @y);
    my $d = Dumpvalue->new();
    ok( $d, 'create a new Dumpvalue object' );
    $d->unwrap(\*BAR);
    $x[0] = $out->read;
    is( $x[0], "-> *main::BAR\n", "unwrap reported ref to typeglob");

    my $e = Dumpvalue->new( globPrint => 1 );
    ok( $e, 'create a new Dumpvalue object, globPrint' );
    $e->unwrap(\*RQP);
    $y[0] = $out->read;
    is( $y[0], "-> *main::RQP\n", "unwrap reported ref to typeglob");

    my $tdir = tempdir( CLEANUP => 1 );
    my $tempfile = File::Spec->catfile($tdir, 'foo.txt');
    open FH, '>', $tempfile or die "Unable to open tempfile for writing";
    print FH "\n";
    my $f = Dumpvalue->new( dumpReused => 1 );
    ok( $f, 'create a new Dumpvalue object' );
    $f->unwrap(\*FH);
    $x[1] = $out->read;
    like( $x[1],
        qr/->\s\*main::FH\n\s*FileHandle\(\{\*main::FH\}\)\s+=>\s+fileno\(\d+\)\n/,
        "unwrap reported ref to typeglob");
    close FH or die "Unable to close tempfile after writing";
}

{
    my (@x, @y);
    my $d = Dumpvalue->new();
    ok( $d, 'create a new Dumpvalue object' );
    $d->set_unctrl('unctrl');
    $d->unwrap([ "bo\007nd", qw| alpha beta gamma | ]);
    $x[0] = $out->read;
    like( $x[0], qr/0\s+"bo\^.nd"\n1\s+'alpha'\n2\s+'beta'\n3\s+'gamma'/,
        "unwrap() with set_unctrl('unctrl') method call" );
}

__END__
    print STDERR "AAA: $x[0]\n";
    print STDERR "AAA: $y[0]\n";

