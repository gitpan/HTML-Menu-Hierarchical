# -*-perl-*-
# Creation date: 2003-01-05 21:34:34
# Authors: Don
# Change log:
# $Id: ItemInfo.pm,v 1.11 2003/03/06 06:26:15 don Exp $
#
# Copyright (c) 2003 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

=pod

=head1 NAME

HTML::Menu::Hierarchical::ItemInfo - Used by HTML::Menu::Hierarchical.
  Provides information about the menu item being processed.

=head1 SYNOPSIS

Created by HTML::Menu::Hierarchical objects.

=head1 DESCRIPTION

Information holder/gatherer representing one menu item.

=head1 METHODS

=head2 Getting back information

=cut

use strict;
use Carp;

{   package HTML::Menu::Hierarchical::ItemInfo;

    use vars qw($VERSION);
    $VERSION = do { my @r=(q$Revision: 1.11 $=~/\d+/g); sprintf "%d."."%02d"x$#r,@r };
    
    sub new {
        my ($proto, $item, $selected_path, $key) = @_;
        my $self = bless {}, ref($proto) || $proto;
        $self->setItem($item);
        $self->setSelectedPath($selected_path);
        $self->setKey($key);
        return $self;
    }

=pod

=head2 hasChildren()

Returns true if the current item has child items in the configuration.
False otherwise.

=cut
    sub hasChildren {
        my ($self) = @_;
        return $self->getItem()->hasChildren;
    }

=pod

=head2 isSelected()

Returns true if the current item is the selected one.

=cut
    sub isSelected {
        my ($self) = @_;
        my $key = $self->getKey;
        if ($self->getItem()->getName eq $self->getKey) {
            return 1;
        }
        
        return undef;
    }

=pod

=head2 isInSelectedPath()

Returns true if the current item is in the path from the root of the
hierarchy to the selected item.

=cut
    sub isInSelectedPath {
        my ($self) = @_;
        my $selected_path = $self->getSelectedPath;
        my $my_item = $self->getItem;

        foreach my $item (@$selected_path) {
            return 1 if $item == $my_item;
        }
        return undef;
    }

=pod

=head2 getSelectedItem()

Returns the ItemInfo object corresponding to the selected menu item.

=cut
    sub getSelectedItem {
        my ($self) = @_;
        my $selected_path = $self->getSelectedPath;
        return $self->new($$selected_path[$#$selected_path], $selected_path, $self->getKey);
    }

=pod

=head2 getSelectedLevel()

Returns the level in the hierarchy where the selected menu item is
located.  Levels start at zero.

=cut
    sub getSelectedLevel {
        my ($self) = @_;
        my $selected_path = $self->getSelectedPath;
        return $#$selected_path;
    }

=pod

=head2 getMaxDisplayedLevel()

Returns the maximum level in the hierarchy to currently be displayed.

=cut
    sub getMaxDisplayedLevel {
        my ($self) = @_;
        my $selected_path = $self->getSelectedPath;
        my $max_level = $#$selected_path;
        if ($$selected_path[$max_level]->hasChildren) {
            $max_level++;
        }
        return $max_level;
    }

=pod

=head2 isOpen()

Returns true if the current menu item is open, i.e., the current item
has child items and is also in the open path.  Return false otherwise.

=cut
    sub isOpen {
        my ($self) = @_;
        if (exists($$self{_is_open})) {
            return $$self{_is_open};
        }

        my $this_item = $self->getItem;
        unless ($this_item->hasChildren) {
            $$self{_is_open} = undef;
            return undef;
        }
        
        my $selected_path = $self->getSelectedPath;
        my $name = $this_item->getName;
        
        foreach my $item (@$selected_path) {
            if ($item->getName eq $name) {
                # print $item->getName . " eq $name\n";
                $$self{_is_open} = 1;
                return 1;
            }
        }

        $$self{_is_open} = undef;
        return undef;
    }

=pod

=head2 isFirstDisplayed()

Returns true if the current menu item is the first one to be
displayed.

=cut
    # added for v0_02
    sub isFirstDisplayed {
        my ($self) = @_;
        my $item = $self->getPreviousItem;
        if ($item) {
            return undef;
        } else {
            return 1;
        }
    }

=pod

=head2 isLastDisplayed()

Returns true if the current menu item is the last to be
displayed.

=cut
    # added for v0_02
    sub isLastDisplayed {
        my ($self) = @_;
        my $item = $self->getNextItem;
        if ($item) {
            return undef;
        } else {
            return 1;
        }
    }

=pod

=head2 getInfo()

Returns the value of the 'info' field for the current menu item
in the navigation configuration.

=cut
    sub getInfo {
        my ($self) = @_;
        return $self->getItem()->getInfo;
    }

=pod

=head2 getName()

Returns the 'name' field for the current menu item in the navigation
configuration.  This is used to determine which menu item has been
selected.

=cut
    sub getName {
        my ($self) = @_;
        return $self->getItem()->getName;
    }


    #####################
    # getters and setters

=pod

=head2 getNextItem()

Returns the ItemInfo object corresponding to the next displayed menu
item.

=cut
    sub getNextItem {
        my ($self) = @_;
        return $$self{_next_item};
    }

    sub setNextItem {
        my ($self, $item) = @_;
        $$self{_next_item} = $item;
    }

=pod

=head2 getPreviousItem()

Returns the ItemInfo object corrsponding to the previously displayed
menu item.

=cut
    sub getPreviousItem {
        my ($self) = @_;
        return $$self{_previous_item};
    }

    sub setPreviousItem {
        my ($self, $item) = @_;
        $$self{_previous_item} = $item;
    }

    sub getKey {
        my ($self) = @_;
        return $$self{_key};
    }
    
    sub setKey {
        my ($self, $key) = @_;
        $$self{_key} = $key;
    }

=pod

=head2 getLevel()

Returns the level in the menu hierarchy where the current menu item is
located.  Levels start at zero.

=cut
    sub getLevel {
        my ($self) = @_;
        return $$self{_level};
    }

    sub setLevel {
        my ($self, $level) = @_;
        $$self{_level} = $level;
    }

    sub getSelectedPath {
        my ($self) = @_;
        return $$self{_selected_path};
    }

    sub setSelectedPath {
        my ($self, $path) = @_;
        $$self{_selected_path} = $path;
    }
    
    sub getItem {
        my ($self) = @_;
        return $$self{_item};
    }
    
    sub setItem {
        my ($self, $item) = @_;
        $$self{_item} = $item;
    }

    ###########
    # utilities

=pod

=head2 Utilities

=head2 my $encoded = $info->urlEncode($plain_text)

URL encodes the given string.  This does full url-encoding, so a
space is %20, not a '+'.

=cut
    sub urlEncode {
        my ($self, $str) = @_;

        $str =~ s|([^A-Za-z0-9_])|sprintf("%%%02x", ord($1))|eg;

        return $str;
    }

=pod

=head2 my $query = $info->urlEncodeVars($var_hash)

Takes a hash containing key/value pairs and returns a url-encoded
query string appropriate for adding to the end of a url.  If a
value is an array, it is assumed to be a multivalued input field
and is added to the query string as such.

=cut
    sub urlEncodeVars {
        my ($self, $hash) = @_;
        my $string;
        my $var;
        my $vars = [ keys %$hash ];
        my @pairs;

        foreach $var (@$vars) {
            my $value = $$hash{$var};
            if (ref($value) eq 'ARRAY') {
                my $name = $self->urlEncode($var);
                foreach my $val (@$value) {
                    push(@pairs, $name . "=" . $self->urlEncode($val));
                }
            } else {
                push(@pairs, $self->urlEncode($var) . "=" . $self->urlEncode($$hash{$var}));
            }
        }

        return join("&", @pairs);
    }

=pod

=head2 my $plain_text = $info->urlDecode($url_enc_str)

Decodes the given url-encoded string.

=cut
    sub urlDecode {
        my ($self, $str) = @_;

        $str =~ tr/+/ /;
        $str =~ s|%([A-Fa-f0-9]{2})|chr(hex($1))|eg;

        return $str;
    }

=pod

=head2 my $var_hash = $info->urlDecodeVars($url_enc_str)

Decodes the url-encoded query string and returns a hash contain
key/value pairs from the query string.  If a field appears more
than once in the query string, it's value will be returned as a
reference to an array of values.

=cut
    sub urlDecodeVars {
        my ($self, $query_string) = @_;
        my $pair;
        my $vars = {};

        foreach $pair (split /\&/, $query_string) {
            my ($name, $field) = map { $self->urlDecode($_) } split(/=/, $pair, 2);

            if (exists($$vars{$name})) {
                my $val = $$vars{$name};
                unless (ref($val) eq 'ARRAY') {
                    $val = [ $val ];
                    $$vars{$name} = $val;
                }
                push @$val, $field;
            } else {
                $$vars{$name} = $field;
            }
        }

        return wantarray ? %$vars : $vars;
    }

=pod

=head2 my $modified_url = $info->addArgsToUrl($url, $var_hash)

Takes the key/value pairs in $var_hash and tacks them onto the
end of $url as a query string.

=cut
    sub addArgsToUrl {
        my ($self, $url, $args) = @_;
        
        if ($url =~ /\?/) {
            $url .= '&' unless $url =~ /\?$/;
        } else {
            $url .= '?';
        }

        my $arg_str;
        if (ref($args) eq 'HASH') {
            $arg_str = $self->urlEncodeVars($args);
        } else {
            $arg_str = $args;
        }

        $url .= $arg_str;
        return $url;
    }

=pod

=head2 my $html = $info->escapeHtml($text)

Escapes the given text so that it is not interpreted as HTML.

=cut

    sub escapeHtml {
        my ($self, $text) = @_;
        
        $text =~ s/\&/\&amp;/g;
        $text =~ s/</\&lt;/g;
        $text =~ s/>/\&gt;/g;
        $text =~ s/\"/\&quot;/g;
        $text =~ s/\$/\&dol;/g;

        return $text;
    }

=pod

=head2 my $text = $info->unescapeHtml($html)

Unescape the escaped text.

=cut
    
    sub unescapeHtml {
        my ($self, $text) = @_;
        $text =~ s/\&amp;/\&/g;
        $text =~ s/\&lt;/</g;
        $text =~ s/\&gt;/>/g;
        $text =~ s/\&quot;/\"/g;
        $text =~ s/\&dol;/\$/g;

        return $text;
    }
    

}

1;

__END__

=pod

=head1 BUGS

    Please send bug reports/feature requests to don@owensnet.com.

=head1 AUTHOR

    Don Owens <don@owensnet.com>

=head1 COPYRIGHT

    Copyright (c) 2003 Don Owens

    All rights reserved. This program is free software; you can
    redistribute it and/or modify it under the same terms as Perl
    itself.

=head1 VERSION

$Id: ItemInfo.pm,v 1.11 2003/03/06 06:26:15 don Exp $

=cut
