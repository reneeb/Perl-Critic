#######################################################################
#      $URL$
#     $Date$
#   $Author$
# $Revision$
########################################################################

package Perl::Critic::Policy::CodeLayout::RequireTidyCode;

use strict;
use warnings;
use English qw(-no_match_vars);
use Perl::Critic::Utils;
use Perl::Critic::Violation;
use base 'Perl::Critic::Policy';

our $VERSION = '0.18';
$VERSION = eval $VERSION;    ## no critic

#----------------------------------------------------------------------------

my $desc = q{Code is not tidy};
my $expl = [ 33 ];

#----------------------------------------------------------------------------

sub default_severity { return $SEVERITY_LOWEST }
sub applies_to { return 'PPI::Document'  }

#----------------------------------------------------------------------------

sub violates {
    my ( $self, $elem, $doc ) = @_;

    # If Perl::Tidy is missing, silently pass this test
    eval { require Perl::Tidy; };
    return if $EVAL_ERROR;

    # Perl::Tidy seems to produce slightly different output, depeding
    # on the trailing whitespace in the input.  As best I can tell,
    # Perl::Tidy will truncate any extra trailing newlines, and if the
    # input has no trailing newline, then it adds one.  But when you
    # re-run it through Perl::Tidy here, that final newline gets lost,
    # which causes the policy to insist that the code is not tidy.
    # This only occurs when Perl::Tidy is writing the output to a
    # scalar, but does not occur when writing to a file.  I may
    # investigate further, but for now, this seems to do the trick.

    my $source = "$doc";
    $source =~ s{ \s+ \Z}{\n}mx;

    my $dest    = $EMPTY;
    my $stderr  = $EMPTY;


    # Perl::Tidy gets confused if @ARGV has arguments from
    # another program.  Also, we need to override the
    # stdout and stderr redirects that the user may have
    # configured in their .perltidyrc file.
    local @ARGV = qw(-nst -nse);  ## no critic

    # Trap Perl::Tidy errors, just in case it dies
    eval {
	Perl::Tidy::perltidy(
	    source      => \$source,
	    destination => \$dest,
	    stderr      => \$stderr,
       );
    };

    if ($stderr || $EVAL_ERROR) {

        # Looks like perltidy had problems
        $desc = q{perltidy had errors!!};
    }


    if ( $source ne $dest ) {
        my $sev = $self->get_severity();
        return Perl::Critic::Violation->new( $desc, $expl, $doc, $sev );
    }

    return;    #ok!
}

1;

#----------------------------------------------------------------------------

__END__

=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireTidyCode

=head1 DESCRIPTION

Conway does make specific recommendations for whitespace and
curly-braces in your code, but the most important thing is to adopt a
consistent layout, regardless of the specifics.  And the easiest way
to do that is to use L<Perl::Tidy>.  This policy will complain if
you're code hasn't been run through Perl::Tidy.

=head1 NOTES

L<Perl::Tidy> is not included in the Perl::Critic distribution.  The
latest version of Perl::Tidy can be downloaded from CPAN.  If
Perl::Tidy is not installed, this policy is silently ignored.

=head1 SEE ALSO

L<Perl::Tidy>


=head1 AUTHOR

Jeffrey Ryan Thalhammer <thaljef@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2005-2006 Jeffrey Ryan Thalhammer.  All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  The full text of this license
can be found in the LICENSE file included with this module.

=cut
