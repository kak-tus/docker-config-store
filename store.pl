#!/usr/bin/env perl

use strict;
use warnings;
use v5.10;
use utf8;

use Cpanel::JSON::XS qw(encode_json);
use HTTP::Request;
use LWP::UserAgent;
use String::Random qw(random_regex);

my $ua = LWP::UserAgent->new;

my $consul = $ENV{CONSUL_HTTP_ADDR};
my $vault  = $ENV{VAULT_ADDR};

store();

while (1) {
  sleep 5;
}

sub store {
  my @consul_vals;
  my @vault_vals;
  my @consul_acl_vals;

  foreach my $env ( keys %ENV ) {
    next unless $env =~ m/^CONF_CONSUL_/;
    my $env_val = $ENV{$env};

    my ( $key, $val ) = $env_val =~ m/^(.+?);(.+)$/s;
    push @consul_vals, { key => $key, val => $val };
  }

  foreach my $env ( keys %ENV ) {
    next unless $env =~ m/^CONF_CONSULACL_/;
    my $env_val = $ENV{$env};

    my ( $token, $name, $type ) = split ';', $env_val;
    push @consul_acl_vals, { token => $token, name => $name, type => $type };
  }

  foreach my $env ( keys %ENV ) {
    next unless $env =~ m/^CONF_VAULT_/;
    my $env_val = $ENV{$env};

    my ( $key, $pass, $regex ) = split ';', $env_val;
    push @vault_vals, { key => $key, pass => $pass, regex => $regex };
  }

  if ( $ENV{CONF_LIST} ) {
    my @env = split /\n/, $ENV{CONF_LIST};
    foreach my $item (@env) {
      $item =~ s/^\s+//;
      $item =~ s/\s+$//;

      my ( $type, $key, $val, $arg ) = split /;/, $item;
      next unless $type;

      if ( $type eq 'consul' ) {
        push @consul_vals, { key => $key, val => $val };
      }
      elsif ( $type eq 'consul_acl' ) {
        push @consul_acl_vals, { token => $key, name => $val, type => $arg };
      }
      elsif ( $type eq 'vault' ) {
        push @vault_vals, { key => $key, pass => $val, regex => $arg };
      }
    }
  }

  if ( scalar @consul_vals ) {
    status_consul();
    store_consul(@consul_vals);
  }

  if ( scalar @vault_vals ) {
    status_vault();
    store_vault(@vault_vals);
  }

  if ( scalar @consul_acl_vals ) {
    status_consul();
    store_consul_acl(@consul_acl_vals);
  }

  return;
}

sub store_consul {
  my @vals = @_;

  foreach my $val (@vals) {
    say "Store consul key $val->{key}";

    my $url = "http://$consul/v1/kv/$val->{key}";

    my $res = $ua->put( $url, Content => $val->{val} );

    unless ( $res->is_success ) {
      say 'Consul store fail';
      exit;
    }

    say "Stored consul key $val->{key}";
  }

  return;
}

sub store_consul_acl {
  my @vals = @_;

  foreach my $val (@vals) {
    say "Store consul ACL $val->{name}";

    $val->{type} ||= 'client';

    my $url = "http://$consul/v1/acl/update";

    my %data = (
      ID   => $val->{token},
      Name => $val->{name},
      Type => $val->{type},
    );
    my $encoded = encode_json( \%data );

    my $res = $ua->put( $url, Content => $encoded );

    unless ( $res->is_success ) {
      say 'Consul store fail';
      exit;
    }

    say "Stored consul ACL $val->{name}";
  }

  return;
}

sub store_vault {
  my @vals = @_;

  foreach my $val (@vals) {
    say "Store vault key $val->{key}";

    unless ( defined $val->{pass} && length $val->{pass} ) {
      $val->{pass} = random_regex( $val->{regex} );
      say "Generate password by regex $val->{regex}";
    }

    my $url = "${vault}v1/$val->{key}";

    my %data = (
      value => $val->{pass},
      ttl   => '1d',
    );
    my $encoded = encode_json( \%data );

    my $req = HTTP::Request->new( 'POST', $url,
      [ 'X-Vault-Token', $ENV{VAULT_TOKEN} ], $encoded );

    my $res = $ua->request($req);

    unless ( $res->is_success ) {
      say 'Vault store fail';
      exit;
    }

    say "Stored vault key $val->{key}";
  }

  return;
}

sub status_vault {
  my $url = "${vault}v1/sys/health";
  my $res = $ua->get($url);

  unless ( $res->is_success ) {
    say 'Vault status fail';
    exit;
  }

  return;
}

sub status_consul {
  my $url = "http://$consul/v1/status/leader";
  my $res = $ua->get($url);

  unless ( $res->is_success ) {
    say 'Consul status fail';
    exit;
  }

  return;
}

