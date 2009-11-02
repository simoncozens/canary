package Email::Store::Decorate;
use strict;

=head1 NAME

Buscador::Decorate - mark a mail body up in HTML

=head1 DESCRIPTION

This provides a method C<format_body> for B<Email::Store::Mail>
which marks up the body of a mail as HTML including making links
clickable, highlighting quotes, and correctly providing links for
names and addresses that we've seen before.


=head1 AUTHOR

Simon Cozens, <simon@cpan.org>

with work from

Simon Wistow, <simon@thegestalt.org>

=head1 COPYRIGHT

Copyright 2004, Simon Cozens

=cut




package Email::Store::Mail;
use strict;
use Text::Decorator;
use Text::Autoformat;
use HTML::Scrubber;

sub format_body {
    my $mail = shift;

    # NOTE! this needs a lot of work 
    my $ct = $mail->simple->header('Content-Type') || "";

    return $mail->body if ($ct =~ m!text/html!i);
    my $html = ($mail->html)[0];
    $html &&= $html->scrubbed();

    my $body = $mail->body;
    my $decorator = Text::Decorator->new($html || $body);

    my %seen;
    my @names =
                #grep {!$seen{$_->thing}++}
                #grep {$_->thing =~ / /}
                #grep {$_->score > 6}
                $mail->named_entities();

    my @addresses = Email::Store::Entity::Address->retrieve_all;

    unless (defined $html) {
    $decorator->add_filter("Quoted", begin => '<span style="display: block;" class="level%i">',
                                     end   => '</span>') ;



    my %uris = map {$_->url => $_->title} $mail->urls();
    $decorator->add_filter("TTBridge" => "html" => "html_entity");
    $decorator->add_filter("CanaryURIFind" => \%uris);
    }
    $decorator->add_filter("NamedEntity" => @names) if @names;
    $decorator->add_filter("Addresses" => @addresses) if @addresses;
    my $html = $decorator->format_as("html");
    return $html;
    
}

package Text::Decorator::Filter::CanaryURIFind;
$INC{"Text/Decorator/Filter/CanaryURIFind.pm"}++; # for ->require
use base 'Text::Decorator::Filter';
use HTML::Entities;
use Carp;
use Text::Decorator::Group;
use Text::Decorator::Node;

sub filter_node {
	my ($class, $args, $node) = @_;
	my $orig = $node->format_as("html");
	return $node unless $orig =~ /http/;
    my %uris = %{$args->[0]};
	my $group = Text::Decorator::Group->new();
	$group->{representations}{text}{pre}  = $node->format_as("text");
	$group->{representations}{html}{pre}  = "";
	$group->{representations}{text}{post} = "";
    # Longest first
    my $uriRe = join "|", sort { length $b <=> length $a} map { quotemeta(encode_entities $_) } keys %uris;
    return unless $uriRe;
    return $node unless $orig =~ /$uriRe/;
	while ($orig =~ s{(.*?)($uriRe)}{}sm) {
		$class->_add_text_node($group, $1 );
        $class->_add_uri_group($group, $2, $uris{$2});
	}
	$class->_add_text_node($group, $orig);

	return $group;
}

sub _add_text_node {
	my ($class, $group, $text) = @_;
	my $node = Text::Decorator::Node->new("");
	$node->{representations}{html} = $text;
	push @{ $group->{nodes} }, $node;
}

sub _add_uri_group {
	my ($class, $group, $uri, $title) = @_;
	my $node = Text::Decorator::Node->new("");
	$node->{representations}{html} = $uri;
    $node->{notes} = "URI";

	my $subgroup = Text::Decorator::Group->new($node);
	$subgroup->{representations}{html}{pre}  = "<a title=\"$title\" href=\"$uri\">";
	$subgroup->{representations}{html}{post} = "</a>";
	push @{ $group->{nodes} }, $subgroup;
}

package Text::Decorator::Filter::NamedEntity;
$INC{"Text/Decorator/Filter/NamedEntity.pm"}++; # for ->require
use Text::Decorator::Group;
use base 'Text::Decorator::Filter';
use HTML::Entities;

sub filter_node {
    my ($class, $args, $node) = @_;
    my (@entities) = @$args;
    # Prepare it.
    return $node if $node->{notes} =~ /URI/;
    $node->{representations}{html} = $node->format_as("html");
    my $test = join "|", map { quotemeta($_->thing)} @entities;
    return $node unless $node->{representations}{html} =~ m{\b?($test)\b?}ims;
    for my $entity (@entities) {
        my ($name) = Email::Store::Entity::Name->search(name => $entity->thing);
        if ($name) {
            my $nn = encode_entities($name->name);
            my $id = $name->id;
            $node->{representations}{html} =~ s{\b\Q$nn\E\b}
                {<a href='/name/view/$id' class='personknown'> <sup><img src='/chrome/personknown.gif' alt='known person' /> </sup>$nn</a>}gmsi;
        } else {
            my $nn = encode_entities($entity->thing);
            my $class = encode_entities($entity->description);
            my $id = $entity->id;
            $node->{representations}{html} =~ s{\b?\Q$nn\E\b?}
                {<a href="/named_entity/view/$id"><span class="entity-$class">$nn</span></a>}gims;
        }
    }
    return $node;
}


package Text::Decorator::Filter::Addresses;
$INC{"Text/Decorator/Filter/Addresses.pm"}++; # for ->require
use base 'Text::Decorator::Filter';
use HTML::Entities;
use Email::Find;

sub filter_node {
    my ($class, $args, $node) = @_;

    my %addresses             = map { $_->address => $_ } @$args;

    $node->{representations}{html} = $node->format_as("html");


     my $finder = Email::Find->new(
        sub {
            my($email, $orig_email) = @_;
            if ($addresses{$orig_email}) {
                my $add = $addresses{$orig_email};
                my $id  = $add->id;
                return "<a href='/address/view/$id' class='personknown'>".
                       " <sup><img src='/chrome/personknown.gif' alt='known person' /> </sup>$orig_email</a>"
            } else {
                return "<sup><img src='/chrome/personunknown.gif' alt='known person' /> </sup>$orig_email";
            }
                                       
    });
    $finder->find(\$node->{representations}{html});    



    return $node;

}

1;
