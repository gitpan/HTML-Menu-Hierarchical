# -*-perl-*-
# Creation date: 2003-01-05 20:47:52
# Authors: Don
# Change log:
# $Id: Item.pm,v 1.4 2003/02/26 06:22:39 don Exp $
#
# Copyright (c) Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

use strict;
use Carp;

{   package HTML::Menu::Hierarchical::Item;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.4 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };

    sub new {
        my ($proto, $name, $info, $children) = @_;
        my $self = bless {}, ref($proto) || $proto;
        $self->setName($name);
        $self->setInfo($info);
        $self->setChildren($children);
        return $self;
    }

    sub hasChildren {
        my ($self) = @_;
        my $children = $self->getChildren;
        if ($children and @$children) {
            return 1;
        }
        return undef;
    }
    
    #####################
    # getters and setters
    
    sub getName {
        my ($self) = @_;
        return $$self{_name};
    }
    
    sub setName {
        my ($self, $name) = @_;
        $$self{_name} = $name;
    }

    sub getInfo {
        my ($self) = @_;
        return $$self{_info};
    }

    sub setInfo {
        my ($self, $info) = @_;
        $$self{_info} = $info;
    }

    sub getChildren {
        my ($self) = @_;
        return $$self{_children};
    }

    sub setChildren {
        my ($self, $children) = @_;
        $$self{_children} = $children;
    }

}

1;

__END__

=head1 NAME


=head1 SYNOPSIS


=head1 EXAMPLES


=head1 Version

$Id: Item.pm,v 1.4 2003/02/26 06:22:39 don Exp $

=cut
