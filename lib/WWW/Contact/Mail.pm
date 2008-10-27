package WWW::Contact::Mail;

use Moose;
extends 'WWW::Contact::Base';

our $VERSION   = '0.01';
our $AUTHORITY = 'cpan:SACHINJSK';

has '+ua_class' => ( default => 'WWW::Mechanize::GZip' );

sub get_contacts {
    my ($self, $email, $password) = @_;

    # reset errstr
    $self->errstr(undef);
    my @contacts;
    
    my $ua = $self->ua;
    $self->debug("start get_contacts from Mail.com");
    
    # get to login form
    $self->get('http://www.mail.com') || return;

    $self->submit_form(
        form_name => 'mailcom',
        fields    => {
            login    => $email,
            password => $password,
        },
    ) || return;
    
    my $content = $ua->content();

     if ($content =~ /Invalid username\/password/ig) {
        $self->errstr('Wrong Username or Password');
        return;
    }
    $self->debug('Login OK');

    $self->get("/scripts/addr/addressbook.cgi?showaddressbook=1") || return;
    $ua->follow_link( text_regex => qr/Import\/Export/i );

    $self->submit_form(
        form_name => 'exportform'
    ) || return;

    my $address_content = $ua->content();
    @contacts = get_contacts_from_csv($address_content);
    
    return wantarray ? @contacts : \@contacts;
}

sub get_contacts_from_csv {
    my ($csv) = shift;
    my @contacts;
 
    # first_name, middle_name, last_name, nickname, e-mail.
    my @lines = split(/\n/, $csv);
    shift @lines; # skip the first line
    foreach my $line (@lines) {
        $line =~ s/"//g;
        my @cols = split(',', $line);
        push @contacts, {
            name  => $cols[0].' '.$cols[2],
            email => $cols[4]
        };
    }
    
    return wantarray ? @contacts : \@contacts;
}

no Moose;

1;
__END__

=head1 NAME

WWW::Contact::Mail - Get contacts from Mail.com

=head1 SYNOPSIS

    use WWW::Contact::Mail;
    
    my $wc       = WWW::Contact::Mail->new();
    my @contacts = $wc->get_contacts('email@mail.com', 'password');
    my $errstr   = $wc->errstr;
    if ($errstr) {
        die $errstr;
    } else {
        print Dumper(\@contacts);
    }

=head1 DESCRIPTION

get contacts from Mail.com. extends L<WWW::Contact::Base>

Mail.com provides email addresses under different domains. Popular ones include:
    mail.com
    email.com
    myself.com
    writeme.com
    usa.com
    iname.com
    techie.com
    
Visit www.mail.com to see the complete list.

=head1 SEE ALSO

L<WWW::Contact>, L<WWW::Contact::Base>, L<WWW::Mechanize::GZip>

=head1 AUTHOR

Sachin Sebastian, C<< <sachinjsk at cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2008 Sachin Sebastian, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut