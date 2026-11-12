use strict;
use warnings;
use HTTP::Tiny;

my ($version, $case) = @ARGV;
die "Usage: $0 <version|all> [case]\n" unless defined $version;
$version = lc $version;
$case = uc $case if defined $case;

my $http = HTTP::Tiny->new;
my $base = "https://docs.cpanel.net/changelogs";

# Numbered cPanel & WHM versions, from the releases page
sub get_versions {
    my $res = $http->get("$base/releases/");
    die "Failed: $res->{status} $res->{reason}\n" unless $res->{success};

    my (%seen, @versions);
    while ($res->{content} =~ m{(\d+)\s+Change\s+Log}g) {
        push @versions, $1 unless $seen{$1}++;
    }
    return @versions;
}

# Additional changelogs (EasyApache, CSF, Installer, etc.)
# Returns a list of [ url, title ]
sub get_additional {
    my $res = $http->get("$base/additional/");
    die "Failed: $res->{status} $res->{reason}\n" unless $res->{success};

    my @pages;
    while ($res->{content} =~
        m{<h4><a href="(https://docs\.cpanel\.net/changelogs/[^"]+/)">([^<]+)</a></h4>}g) {
        push @pages, [ $1, $2 ];
    }
    return @pages;
}

# $extra = 0 for numbered cPanel versions, 1 for additional changelogs
sub check_page {
    my ($url, $label, $wanted, $extra) = @_;

    my $res = $http->get($url);
    unless ($res->{success}) {
        warn "Failed to fetch $label: $res->{status} $res->{reason}\n";
        return 0;
    }

    # Version pages use <h3 id="..">138.0.20</h3> and "Fixed CPANEL-..." items.
    # Additional pages are matched more loosely (any h2/h3, any <li>).
    my $heading_re = $extra
        ? qr{<h[23][^>]*>\s*([^<]+?)\s*</h[23]>}
        : qr{<h3 id="\d+">([\d.]+)</h3>$};

    my $li_re;
    if (defined $wanted) {
        $li_re = $extra
            ? qr{^\s*<li>(.*\Q$wanted\E\b.*)</li>\s*$}i
            : qr{^<li>((Fixed|Improved)\s+\Q$wanted\E\b.*)</li>$}i;
    }
    else {
        $li_re = $extra
            ? qr{^\s*<li>(.*)</li>\s*$}
            : qr{^<li>((?:Fixed|Improved|\[Security\]).*)</li>$};
    }

    my $current_heading;
    my $printed_heading = 0;
    my $printed_label   = 0;
    my $found           = 0;
    my $capture_cve     = 0;
    my $parent;                 # nearest preceding non-CVE <li> in the same list
    my $printed_parent  = 0;
    my $any_li_re       = qr{^\s*<li>(.*)</li>\s*$};

    print "== $label ==\n" if $extra && !defined $wanted;

    for my $line (split /\n/, $res->{content}) {

        # A new list or heading means the previous update no longer applies
        if ($line =~ m{</ul>|<h[1-6]}) {
            undef $parent;
            $printed_parent = 0;
        }

        # After a wanted entry matched, also print the (CVE-...) lines
        # that follow it, until the list or section ends.
        if ($capture_cve) {
            if ($line =~ m{^\s*<li>(\(CVE-\d+-\d+\).*)</li>\s*$}) {
                (my $cve = $1) =~ s{</?code\b[^>]*>}{}gi;
                print "$cve\n";
                next;
            }
            $capture_cve = 0 if $line =~ m{</ul>|<h[1-6]};
        }

        if ($line =~ $heading_re) {
            $current_heading = $1;
            $printed_heading = 0;
            print "$1\n" unless defined $wanted;
        }
        elsif ($line =~ $li_re) {
            my $text = $1;
            $text =~ s{</?code\b[^>]*>}{}gi;    # strip <code> and </code>
            if (defined $wanted) {
                $found = 1;
                # Don't start capturing if the match was itself a CVE line
                $capture_cve = 1 if $text !~ /^\(CVE-/;
                if ($extra && !$printed_label) {
                    print "== $label ==\n";
                    $printed_label = 1;
                }
                if (!$printed_heading && defined $current_heading) {
                    print "$current_heading\n";
                    $printed_heading = 1;
                }
                # Searching for a CVE: show the update it belongs to first
                if ($text =~ /^\(CVE-/ && defined $parent && !$printed_parent) {
                    print "$parent\n";
                    $printed_parent = 1;
                }
            }
            print "$text\n";
        }
        elsif ($line =~ $any_li_re) {
            # Remember the most recent non-CVE entry as the "parent" update
            my $t = $1;
            if ($t !~ /^\(CVE-/) {
                ($parent = $t) =~ s{</?code\b[^>]*>}{}gi;
                $printed_parent = 0;
            }
        }
    }

    return $found;
}

my $found_any = 0;

if ($version eq 'all') {
    for my $ver (get_versions()) {
        $found_any = 1 if check_page("$base/$ver-change-log/", $ver, $case, 0);
    }
    for my $page (get_additional()) {
        my ($url, $title) = @$page;
        $found_any = 1 if check_page($url, $title, $case, 1);
    }
}
else {
    $found_any = check_page("$base/$version-change-log/", $version, $case, 0);
}

if (defined $case && !$found_any) {
    my $where = $version eq 'all' ? 'any changelog' : "the $version changelog";
    print "No entries found for $case in $where\n";
    exit 1;
}
