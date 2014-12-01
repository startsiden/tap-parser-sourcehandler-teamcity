package TAP::Parser::SourceHandler::TeamCity;
#ABSTRACT: Handle "TAP" sources that produce TeamCity output, by converting

use warnings;
use strict;

use Role::Tiny::With;

with 'TAP::Parser::SourceHandler::JavaScript';

use TAP::Parser::IteratorFactory   ();
use TAP::Parser::Iterator::Process::TeamCity ();

our @ISA = qw( TAP::Parser::SourceHandler );
TAP::Parser::IteratorFactory->register_handler(__PACKAGE__);

sub _name { 'TeamCity' }

sub make_iterator {
    my ( $class, $source ) = @_;

    my $config = $source->config_for( $class->_name );
    my @command = ( $config->{bin}, $config->{args} );
    
    my $fn = ref $source->raw ? ${ $source->raw } : $source->raw;

    push @command, $fn;

    return TAP::Parser::Iterator::Process::TeamCity->new( {
            command => \@command,
            merge   => $source->merge,
        }
    );
}


1;
