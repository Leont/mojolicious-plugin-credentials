package Mojolicious::Plugin::Credentials;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';

use Carp 'croak';
use Crypt::Credentials 0.002;
use File::Spec::Functions 'catdir';

sub _get_dir {
	my ($self, $config) = @_;

	if ($config->{dir}) {
		return $config->{dir};
	} else {
		my $home = Mojo::Home->new;
		$home->detect;
		return catdir($home->to_string, 'credentials');
	}
}

sub _get_keys {
	my ($self, $config) = @_;
	if ($config->{keys}) {
		return @{ $config->{keys} };
	} elsif (defined $ENV{MOJO_CREDENTIALS_KEY}) {
		my @encoded_keys = split /:/, $ENV{MOJO_CREDENTIALS_KEYS};
		return map { pack 'H*', $_ } @encoded_keys;
	} else {
		croak 'No credentials key given';
	}
}

sub register {
	my ($self, $app, $config) = @_;

	my $dir  = $self->_get_dir($config);
	my @keys = $self->_get_keys($config);

	my $credentials = Crypt::Credentials->new(dir => $dir, keys => \@keys);

	$app->helper(credentials => sub { $credentials });

	return;
}

1;

# ABSTRACT: A credentials store in mojo

=head1 SYNOPSIS

 # Mojolicious::Lite

 plugin 'Credentials';

 # Mojolicious

 sub startup {
   my $self = shift;

   $self->plugin('Credentials');
 }
 
=head1 DESCRIPTION

This module plugs L<Crypt::Credentials|Crypt::Credentials> into your Mojolicious application. This allows you to store credentials using only one key.

Credentials can by edited using the credentials mojo command (e.g. C<./myapp.pl credentials edit google>.

=head1 CONFIGURATION

It takes two arguments, both optional.

=over 4

=item * keys

This is the key used to encrypt the credentials. If not given this will use the environmental variable C<MOJO_CREDENTIALS_KEYS> (split on colons), and otherwise it will bail out. In both cases the key will be expected in hexadecimal form.

=item * dir

This is the directory of the credentials. If not given it will default to C<$MOJO_HOME/credentials>, or if C<MOJO_HOME> isn't defined C<./credentials>.

=back

=head1 HELPERS

=head2 credentials

This will return the appropriately configured C<Crypt::Credentials> object.

 my ($username, $password) = credentials->get_yaml('google')->@{'username', 'password'};
