use Test::More tests=>71;

use_ok("Text::PhoneScan");
my $s;

eval { $s = Text::PhoneScan->new(); };

like($@, qr/given/, "Can't instantiate without text");

$s=Text::PhoneScan->new("Foo");
isa_ok($s, "Text::PhoneScan");

sub phone_ok {
    my ($line, $want) = @_;
    my $s = Text::PhoneScan->new($line);
    my @want = ref $want ? @$want : ($want);
    my @found = $s->numbers;
    ok(eq_set(\@found, \@want), "Phone check: $line") || do {
       my %found = $s->numbers_by_scanner;
       print ("# In string: $line\n");
       for (keys %found) {
           print ("# $found{$_} found <$_>\n");
       }
       print ("# Did not find <$_>\n") foreach grep !$found{$_}, @want;
    
    };
}

my @phones = map +($_ => $_), exact_matches();
push @phones, phone_matches();
while (my ($got, $want) = splice @phones, 0, 2) {
    phone_ok($got => $want);
}

sub exact_matches {
	(
		'9024 6964', # N.I. number
		'02890 246964', # N.I. number
		'02890 246 964',
		'02890 24 69 64',
		'028 9024 6964',
		'028 90 24 69 64',
		'(028) 9024 6964',
		'+44 028 9024 6964', # N.I. No with International Code
		'+44 28 9024 6964',
		'+44 (0)28 9024 6964',
		'07866366684',
		'+44 (0) 207 691 1880 ext:224',
		'028 9050 9050 ext 123',
		'028 9050 9050 EXT. 2345',
		'0117 970 6999', # Glasgow number
		'0199 442 7969', # Welsh number
		'020 7937 2345', # London number
		'+353 086 827 6047',    # Ireland
		'+353 (0) 91 751054', # Ireland
		'0800 316 3876', # UK Free Phone
		'0800 3163876',  # UK Free Phone
		'0845 120 9637', # UK Local Rate
		'0845 1209637',  # UK Local Rate
		'0870 444 7766', # UK National Rate 
		'0906 759 0216', # UK Premium Rate
		'0909 668 1066', # UK Premium Rate
		'(888)270-9111', # Canadian Number
		'1-800-555-TELL', # American Toll Free number
		'(800) 322-2711', # American Toll Free number
		'01 45 74 85 85', # French phone number
	);
}

sub phone_matches {
	(
		'Tel: (028) 9024 6964'                        => '(028) 9024 6964',
		'My phone number is (028) 9024 6964.'         => '(028) 9024 6964',
		'Tel: (028) 9024 6964 / Fax: (028) 9024 6965' =>
			[ '(028) 9024 6964', '(028) 9024 6965' ],
		'Telephone: (405) 732-0324 Tulsa',            => '(405) 732-0324',
		'Mobile: +44 (0)79 0990 5220',                => '+44 (0)79 0990 5220',
		'Fax: + 44 (0)1305 789000',                   => '+ 44 (0)1305 789000',
		'P: (028) 9024 6964',                         => '(028) 9024 6964',
		'Mob: +44 7866 366684',                       => '+44 7866 366684',
		'M: +44 7866 366684',                         => '+44 7866 366684',
		'His number is 9044 5100',                    => '9044 5100',
		't: +44 (0)207 691 1880 ext:224',             => '+44 (0)207 691 1880 ext:224',
		'f: +44 (0)207 691 1880',                     => '+44 (0)207 691 1880',
		'Her number is 90594600',                     => '90594600',
		'Her number is: 90817257',                    => '90817257',
		'His number is: 90445100',                    => '90445100',
		'My mobile number is 07866366684',            => '07866366684',
		'My mobile number is: 07866366684',           => '07866366684',
		'You can contact me at: 07866366684',         => '07866366684',
		'DD: 02890560544',                            => '02890560544',
		'Ring me at: (028)90246964',                  => '(028)90246964',
		'Call me on (028)90246964',                   => '(028)90246964',
		'ISBN: 0201708574',                           => [],
		'isbn="0201708574"',                          => [],
		'Contact me on: 02893373149',                 => '02893373149',
		'44 118 9502111'                              => '+44 118 9502111',
        ' My phone is 617-482-3258  x216. '           => '617-482-3258  x216',
        'my no. is in case you didnt know....+353 61 354610.' 
                                                      => '+353 61 354610',
        'Contact me on: 02893373149',         => '02893373149',
        'Paul Sharpe                      Tel: 619 523 0100
             Russell Sharpe, Inc              Fax: 619 523 0101
             4993 Niagara Avenue, Suite 209   mailto:paul@russellsharpe.com
         San Diego, CA 92107-3185', => [ '619 523 0100', '619 523 0101' ],
        'At 08:48 -0700 2001.10.02, Randal L. Schwartz wrote:', => [],
        'http://www.google.com/search?sourceid=navclient&ie=UTF-8&oe=UTF-8&q=442890246964'
        , => [],
        "Just phoning you now. If I dont't get you I'm at 245133x3178", =>
            '245133x3178',
        'T +44 (0)28 90321320 
         F +44 (0)28 90329656', =>
            [ '+44 (0)28 90321320', '+44 (0)28 90329656' ],
        'Message-Id: <p05100304ba8a81ed3573@[217.134.113.94]>' => [],
'Can you contact Mihoko today? Am sorry I dont have enough money to ring. She wants to know when you are at home.
Love,
Keiko


From adum@adum.com  Sun Mar  2 13:45:19 2003' => [],
'x
        (028) 9090 9040: Tel
        (028) 9090 9050: Fax' => ["(028) 9090 9040", "(028) 9090 9050" ],
'Tel: +44 (0)28 9032 9555       Fax: +44 (0)28 9033 0549
 ISDN: +44 (0)28 9022 1188      Mobile: +44 (0)79 0990 5220'
     => ["+44 (0)28 9032 9555", "+44 (0)28 9033 0549", 
         "+44 (0)28 9022 1188", "+44 (0)79 0990 5220"],
         'Phone number

my phone number is 01269 824264.' => ["01269 824264"],
	);
}

1;
