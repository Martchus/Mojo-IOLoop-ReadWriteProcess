package Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

# Refer to https://www.kernel.org/doc/Documentation/cgroup-v1/ for details

use Mojo::Base 'Mojo::IOLoop::ReadWriteProcess::CGroup';
use Mojo::File 'path';
use Mojo::Collection 'c';

our @EXPORT_OK = qw(cgroup);
use Exporter 'import';

use constant {PROCS_INTERFACE => 'cgroup.procs', TASKS_INTERFACE => 'tasks'};

use Scalar::Util ();
use Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PID;

has controller => '';

sub _cgroup {
  path($_[0]->parent
    ?
      path($_[0]->_vfs, $_[0]->controller, $_[0]->name, $_[0]->parent)
    : path($_[0]->_vfs, $_[0]->controller, $_[0]->name));
}

sub child {
  return $_[0]->new(
    name       => $_[0]->name,
    controller => $_[0]->controller,
    parent     => $_[0]->parent ? path($_[0]->parent, $_[1]) : $_[1])->create;
}

has pid => sub {
  my $pid
    = Mojo::IOLoop::ReadWriteProcess::CGroup::v1::PID->new(cgroup => shift);
  Scalar::Util::weaken $pid->{cgroup};
  return $pid;
};


# CGroups process interface
sub add_process {
  $_[0]->_appendln($_[0]->_cgroup->child(PROCS_INTERFACE) => pop);
}

sub process_list { shift->_list(PROCS_INTERFACE) }
sub processes    { c(shift->_listarray(PROCS_INTERFACE)) }

sub contains_process { shift->_contains(+PROCS_INTERFACE() => pop) }

# CGroups thread interface
sub add_thread {
  $_[0]->_appendln($_[0]->_cgroup->child(TASKS_INTERFACE) => pop);
}

sub thread_list { shift->_list(TASKS_INTERFACE) }

sub contains_thread { shift->_contains(+TASKS_INTERFACE() => pop) }

1;

=encoding utf-8

=head1 NAME

Mojo::IOLoop::ReadWriteProcess::CGroup::v1 - CGroups v1 implementation.

=head1 SYNOPSIS

    use Mojo::IOLoop::ReadWriteProcess::CGroup::v1;

    my $cgroup = Mojo::IOLoop::ReadWriteProcess::CGroup::v1->new( name => "test" );

    $cgroup->create;
    $cgroup->exists;
    my $child = $cgroup->child('bar');

=head1 DESCRIPTION

This module uses features that are only available on Linux,
and requires cgroups and capability for unshare syscalls to achieve pid isolation.

=head1 METHODS

L<Mojo::IOLoop::ReadWriteProcess::CGroup::v1> inherits all methods from L<Mojo::Base> and implements
the following new ones.

=head1 LICENSE

Copyright (C) Ettore Di Giacinto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Ettore Di Giacinto E<lt>edigiacinto@suse.comE<gt>

=cut
