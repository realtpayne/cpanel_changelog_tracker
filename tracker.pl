use strict;
use warnings;
use HTTP::Tiny;

my ($version, $case) = @ARGV;
die "Usage: $0 <version|all> [case]\n" unless defined $version;
$case = uc $case if defined $case;

my $http = HTTP::Tiny->new;

sub get_versions {
    my $res = $http->get("https://docs.cpanel.net/changelogs/releases/");
    die "Failed: $res->{status} $res->{reason}\n" unless $res->{success};

    my (%seen, @versions);
    while ($res->{content} =~ m{(\d+)\s+Change\s+Log}g) {
        push @versions, $1 unless $seen{$1}++;
    }
    return @versions;
}

sub check_version {
    my ($ver, $case) = @_;

    my $res = $http->get("https://docs.cpanel.net/changelogs/$ver-change-log/");
    unless ($res->{success}) {
        warn "Failed to fetch $ver: $res->{status} $res->{reason}\n";
        return 0;
    }

    my $current_version;
    my $printed_version = 0;
    my $found = 0;

    for my $line (split /\n/, $res->{content}) {
        if ($line =~ m{<h3 id="\d+">([\d.]+)</h3>$}) {
            $current_version = $1;
            $printed_version = 0;
            print "$1\n" unless defined $case;
        }
        elsif (defined $case) {
            if ($line =~ m{^<li>((Fixed|Improved)\s+\Q$case\E\b.*)</li>$}) {
                $found = 1;
                if (!$printed_version) {
                    print "$current_version\n";
                    $printed_version = 1;
                }
                print "$1\n";
            }
        }
        elsif ($line =~ m{^<li>((?:Fixed|Improved|\[Security\]).*)</li>$}) {
            print "$1\n";
        }
    }

    return $found;
}

my @versions = $version eq 'all' ? get_versions() : ($version);

my $found_any = 0;
for my $ver (@versions) {
    $found_any = 1 if check_version($ver, $case);
}

if (defined $case && !$found_any) {
    my $where = $version eq 'all' ? 'any changelog' : "the $version changelog";
    print "No entries found for $case in $where\n";
    exit 1;
}
