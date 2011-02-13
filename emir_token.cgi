#! /usr/bin/perl
	# HTTP/1.1 200 OK
	my @t=localtime();
	my $t=sprintf("%s.%02d.%02d_%02d:%02d",$t[5]+1900,$t[4],$t[3],$t[2],$t[1]);
	print "Content-Length: 0\r\n";
	print "Token: $t\r\n\r\n"; # print Token header
exit 0;
