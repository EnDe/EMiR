#! /usr/bin/perl
	# HTTP/1.1 200 OK
	my @t=localtime();
	my $t=sprintf("%s.%02d.%02d %02d:%02d:",$t[5]+1900,$t[4],$t[3],$t[2],$t[1]);
	print "Content-Length: 0\r\n";
	print "Content-Type: text/plain\r\n\r\n";
	open (F, ">>", "./emir_result.log") or die "**ERROR: $!\n";
	#print F "$t GET:\t: $ENV{'QUERY_STRING'}\n";
	print F "$t POST:\t:";
	print F while (<>);
	print F "\n";
	close F;
exit 0;
