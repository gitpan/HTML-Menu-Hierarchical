# -*-perl-*-
# Creation date: 2003-01-05 20:35:53
# Authors: Don
# Change log:
# $Id: Hierarchical.pm,v 1.23 2003/04/09 04:44:30 don Exp $
#
# Copyright (c) 2003 Don Owens
#
# All rights reserved. This program is free software; you can
# redistribute it and/or modify it under the same terms as Perl
# itself.

=pod

=head1 NAME

HTML::Menu::Hierarchical - HTML Hierarchical Menu Generator

=head1 SYNOPSIS

    my $menu_obj = HTML::Menu::Hierarchical->new($conf, \&callback);
    my $html = $menu_obj->generateMenu($menu_item);

    or

    my $menu_obj = HTML::Menu::Hierarchical->new($conf, [ $obj, $method ]);
    my $html = $menu_obj->generateMenu($menu_item);

    In the first case, the callback is a function.  In the second, the
    callback is a method called on the given object.

    The $conf parameter is a navigation configuration data structure
    (described below).

=head1 DESCRIPTION

    HTML::Menu::Hierarchical provides a way to easily
    generate a hierarchical HTML menu without forcing a specific
    layout.  All output is provided by your own callbacks (subroutine
    refs) and your own navigation configuration.

=head2 configuration data structure

    A navigation configuration is a reference to an array whose
    elements are hashrefs.  Each hash contains configuration
    information for one menu item and its children, if any.  Consider
    the following example:

    my $conf = [
                { name => 'top_button_1',
                  info => { text => 'Top Level Button 1',
                            url => '/'
                          },
                  open => 1, # force this item's children to be displayed
                  children => [
                               { name => 'button_1_level_2',
                                 info => { text => "Child 1 of Button 1",
                                           url => '/child1.cgi'
                                         },
                               },

                              ]
                },

                { name => 'top_button_2',
                  info => { text => 'Top Level Button 2',
                            url => '/top2.cgi'
                          },
                  callback => [ $obj, 'my_callback' ]
                },
                
               ];

    In each hash, the 'name' parameter should correspond to the
    $menu_item parameter passed to the generateMenu() method.
    This is how the module computes which menu item is selected.
    This is generally passed via a CGI parameter, which can be
    tacked onto the end of the url in your callback function.
    Note that this parameter must be unique among all the array
    entries.  Otherwise, the module will not be able to decide
    which menu item is selected.

    The value of the 'info' parameter is available to your
    callback function via the getInfo() method called on the
    HTML::Menu::Hierarchical::ItemInfo object passed to the
    callback function.  In the above example, the 'info'
    parameter contains text to be displayed as the menu item, and
    a url the user is sent to when clicking on the menu item.

    The 'children' parameter is a reference to another array
    containing configuration information for child menu items.
    This is where the Hierarchical part comes in.  There is no
    limit to depth of the hierarchy (until you run out of RAM,
    anyway).

    If a 'callback' parameter is specified that callback will be
    used for that menu item instead of the global callback passed
    to new().

    An 'open' parameter can be specified to force an item's
    children to be displayed.  This can be a scalar value that
    indicates true or false.  Or it can be a subroutine reference
    that returns a true or false value.  It can also be an array,
    in which case the first element is expected to be an object,
    the second element the name of a method to call on that
    object, and the rest of the elements will be passed as
    arguments to the method.  If an 'open_all' parameter is
    passed, the current item and all items under it in the
    hierarchy will be forced open.

=head2 callback functions/methods

    Callback functions are passed a single parameter: an
    HTML::Menu::Hierarchical::ItemInfo object.  See the
    documentation on this object for available methods.  The
    callback function should return the HTML necessary for the
    corresponding menu item.

=cut

use strict;
use Carp;

{   package HTML::Menu::Hierarchical;

    use vars qw($VERSION);
    BEGIN {
        $VERSION = 0.06; # update below in POD as well
    }

    use HTML::Menu::Hierarchical::Item;
    use HTML::Menu::Hierarchical::ItemInfo;

=pod

=head1 METHODS

=head2 new()

    my $menu_obj = HTML::Menu::Hierarchical->new($conf, \&callback);

=cut

    sub new {
        my ($proto, $menu_config, $iterator_sub) = @_;
        my $self = bless {}, ref($proto) || $proto;
        $self->setConfig($self->_convertConfig($menu_config));
        $self->setIterator($iterator_sub);
        return $self;
    }

=pod

=head2 generateMenu()
    
    my $html = $menu_obj->generateMenu($menu_item);

    $menu_item is the 'name' parameter of the selected item,
    typically passed as a CGI parameter.

=cut

    sub generateMenu {
        my ($self, $key) = @_;

        my $str;
        my $items = $self->generateOpenList($key);
        foreach my $item (@$items) {
            $str .= $self->_generateMenuSection($item);
        }

        $self->_cleanUpOpenlist($items);
        
        return $str;
    }
    *generate_menu = \&generateMenu;

=pod

=head2 addChildConf()

    $menu_obj->addChildConf($conf, $menu_item_name);

    Adds another configuration tree into the current
    configuration at the specified node (name of the menu item).

=cut
    # added for v0_02
    sub addChildConf {
        my ($self, $conf, $menu_item) = @_;

        return undef unless $conf;

        my $selected_item = $self->getSelectedItem($menu_item);
        return undef unless $selected_item;

        my $converted_conf = $self->_convertConfig($conf);
        $selected_item->setChildren($converted_conf);

        return 1;
    }
    *add_child_conf = \&addChildConf;
    
    sub generateOpenList {
        my ($self, $key) = @_;

        my $conf = $self->getConfig;
        return '' unless $conf;

        my $selected_path = $self->findSelectedPath($conf, $key);
        my $list = [];
        foreach my $item (@$conf) {
            my $l = $self->_generateOpenList($item, $key, $selected_path, 0);
            push @$list, @$l;
        }

        my $last_item;
        foreach my $item (@$list) {
            if ($last_item) {
                $item->setPreviousItem($last_item);
                $last_item->setNextItem($item);
            }

            $last_item = $item;
        }

        return $list;
    }

    # cleans up circular references in the open list so perl will
    # deallocate the memory used
    sub _cleanUpOpenlist {
        my ($self, $list) = @_;

        foreach my $item (@$list) {
            $item->setPreviousItem(undef);
            $item->setNextItem(undef);
        }
    }

    sub _generateOpenList {
        my ($self, $item, $key, $selected_path, $level, $parent) = @_;
        my $new_level = $level + 1;
        my $list = [];

        my $info_obj =
            HTML::Menu::Hierarchical::ItemInfo->new($item, $selected_path, $key, $parent);
        
        $info_obj->setLevel($level);
        push @$list, $info_obj;

        if ($info_obj->isOpen and $info_obj->hasChildren) {
            foreach my $child (@{$item->getChildren}) {
                my $l = $self->_generateOpenList($child, $key, $selected_path, $new_level,
                                                $info_obj);
                push @$list, @$l;
            }
        }
        
        return $list;
    }
    
    sub _generateMenuSection {
        my ($self, $info_obj) = @_;
        
        my $str;
        my $iterator = $info_obj->getOtherField('callback');
        $iterator = $self->getIterator unless $iterator;
        
        if (ref($iterator) eq 'ARRAY') {
            my ($obj, $meth) = @$iterator;
            $str .= $obj->$meth($info_obj);
        } else {
            $str .= $iterator->($info_obj);
        }
        
        return $str;
    }

    sub findSelectedPath {
        my ($self, $conf, $key) = @_;
        return undef unless $conf;
        
        foreach my $item (@$conf) {
            if ($item->getName eq $key) {
                return [ $item ];
            }
            my $path = $self->findSelectedPath($item->getChildren, $key);
            if ($path) {
                unshift @$path, $item;
                return $path;
            }
        }
        
        return undef;
    }

    sub getSelectedItem {
        my ($self, $key) = @_;
        my $path = $self->findSelectedPath($self->getConfig, $key);
        return undef unless $path;
        return pop(@$path);
    }

    sub _convertConfig {
        my ($self, $conf) = @_;
        
        my $obj_array = [];
        foreach my $item (@$conf) {
            if (ref($item) eq 'HTML::Menu::Hierarchical::Item') {
                push @$obj_array, $item;
                next;
            }
            my $children;
            if (my $new_conf = $$item{children}) {
                $children = $self->_convertConfig($new_conf);
            }
            my $item = HTML::Menu::Hierarchical::Item->new(@$item{'name', 'info'}, $children,
                                                          $item);
            push @$obj_array, $item;
        }

        return $obj_array;
    }
    
    #####################
    # getters and setters
    
    sub getConfig {
        my ($self) = @_;
        return $$self{_menu_config};
    }
    
    sub setConfig {
        my ($self, $conf) = @_;
        $$self{_menu_config} = $conf;
    }

    sub getIterator {
        my ($self) = @_;
        return $$self{_iterator};
    }
    
    sub setIterator {
        my ($self, $iterator) = @_;
        $$self{_iterator} = $iterator;
    }


}

1;

__END__

=pod

=head2 There are also underscore_separated versions of these methods.

    E.g., unescapeHtml($html) becomes unescape_html($html)

=head1 EXAMPLES

    See the scripts in the examples subdirectory for example usages.

    See the documentation for HTML::Menu::Hierarchical::ItemInfo for
    methods available via the $info_obj parameter passed to the
    menu_callback function below.

=over 4

sub menu_callback {
    my ($info_obj) = @_;
    my $info_hash = $info_obj->getInfo;
    my $level = $info_obj->getLevel;

    my $text = $$info_hash{text};
    $text = '&nbsp;' if $text eq '';
    my $item_arg = $info_obj->getName;

    # Add a cgi parameter m_i to url so we know which menu
    # item was chosen
    my $url = $info_obj->addArgsToUrl($$info_hash{url},
                                      { m_i => $item_arg });

    my $dpy_text = $info_obj->isSelected ? "&lt;$text&gt" : $text;
    my $spacer = '&nbsp;&nbsp;' x $level;
    my $str = qq{<tr>\n};
    $str .= qq{<td bgcolor="#cccc88"><a href="$url">};
    $str .= $spacer . $dpy_text;
    $str .= qq{</a></td>};
    $str .= qq{</tr>\n};
    return $str;
}


=back

=head1 TODO

=over 4


=item Drop down to first url

Provide a way to skip being selected, e.g., if a menu item is
selected that contains no url to go to, default to the first of
its children that contains to a url.

=item Last sibling

Provide a way to tell if the current menu item is the last
of its siblings to be displayed.

=back


=head1 BUGS

    Please send bug reports/feature requests to don@owensnet.com.

    There are currently no checks for loops in the configuration data
    structure passed to the module.

=head1 AUTHOR

    Don Owens <don@owensnet.com>

=head1 COPYRIGHT

    Copyright (c) 2003 Don Owens

    All rights reserved. This program is free software; you can
    redistribute it and/or modify it under the same terms as Perl
    itself.

=head1 VERSION

    0.06

=cut
