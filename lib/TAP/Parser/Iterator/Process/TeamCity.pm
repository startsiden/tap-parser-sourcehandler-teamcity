package TAP::Parser::Iterator::Process::TeamCity;
#ABSTRACT: Run a process that produces TeamCity reports, live convert to TAP.
#


use parent 'TAP::Parser::Iterator::Process';

use Class::Method::Modifiers;
use TeamCity::Parser;
use TAP::SimpleOutput;

# We need to wrap _next, to get the "real" next sub, and then wrap it with
# something that will keep track of TeamCity report status, and convert it to
# TAP
#

my $parser = TeamCity::Parser->new();

around '_next' => sub {
    my $orig = shift;
    # Get the orig subref
    my $next = $orig->(@_);

    # We need to keep track of state somehow here as well?
    my $count = 0; # test count for current suite?
    my $suite_count = 0;
    my @buf;
    return sub {

        return shift @buf if scalar(@buf);
        # Lets get the next from the underlying process suplier
        my $event;
        do {
            my $line = $next->();
            $event = $parser->parse($line);
        } until ($event);# and $event->isa('TeamCity::Parser::Node::Suite'));
        # lets convert event into TAP then?
        # XXX: Closed design and quite ugly! :(

        if ($event->isa('TeamCity::Parser::End')) {
            push(@buf, "1..$suite_count", undef); # the undef decalres the END of this iterator
        } elsif ($event->isa('TeamCity::Parser::Node::Test')) {
            $count++;
            push (@buf, "    " . ($event->ok ? "ok" : "not ok") . " $count - " . $event->name);
            unless ($event->ok) {
                push(@buf, "    # " . $event->diag);
            }
        } else { # should be suite end?
            $suite_count++;
            push( @buf, ($event->ok ? "ok" : "not ok") . " $suite_count - " . $event->name);
            my $c = $count;
            $count = 0;
            push(@buf, "    " . "1..$c");
        }

        return shift @buf if scalar(@buf);

    }
};


1;
