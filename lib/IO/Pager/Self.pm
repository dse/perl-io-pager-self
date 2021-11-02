package IO::Pager::Self;
use warnings;
use strict;

use base 'Exporter';
our @EXPORT;
our @EXPORT_OK = qw(pager);
our %EXPORT_TAGS = (
    ':all' => [qw(pager)],
);

use POSIX qw(dup2);

sub pager {
    if (!(-t fileno(\*STDOUT) && -t fileno(\*STDIN))) {
        return;
    }

    my $pager = $ENV{GIT_GRAPH2_PAGER} // $ENV{GIT_PAGER} // $ENV{PAGER} // 'less';

    my ($childInput, $parentOutput);
    pipe($childInput, $parentOutput) or die("pipe: $!");
    my $pid = fork();
    die("fork: $!") if !defined $pid;

    my $me = sub {
        dup2(fileno($parentOutput), 1) or die("dup2: $!");
    };
    my $less = sub {
        dup2(fileno($childInput), 0) or die("dup2: $!");
        exec($pager) or die("exec: $!");
    };

    if ($pid) {
        # parent
        $less->();
    } else {
        # child
        $me->();
    }
}

1;
