#! /usr/bin/perl -w
#?
#? NAME
#?      $0 - tag content generator for EMiR - Event Mappings in Reality
#?
#? SYNOPSIS
#?      $0 [<options>] <TAG>
#?
#? OPTIONS
#?      --h         this text
#?      --js        only print JavaScript part from emir.html
#?      --dbx-tty   print debug information on console's (tty) STDERR
#?      --dbx-html  print debug information as HTML comment in generated data
#?
#? DESCRIPTION
#?      Generates a complete HTML content and prints on  STDOUT. The generated
#?      content contains all known event attributes for the specified <TAG>.
#?      The generated content (when saved to a file) is destined to be used as
#?      link (to the saved file) in  emir.html  for the corresponding <TAG>.
#?
#?      NOTE that only one  TAG  is expected as argument. If more than one TAG
#?      is specified, content for each will be generated.
#?
#?      Beside some constant text (content) the generated HTML looks like:
#?
#?          <head> ...
#?               <TAG id="TAG"\
#?                 EVENT0="return $e$(this,'EVENT0');"
#?                 EVENT1="return $e$(this,'EVENT1');"
#?                 EVENT...
#?               >-test me-</TAG>
#?          <body>
#?          <div><fieldset><span> <TAG> </span>
#?               <label id="l-TAG-EVENT0">\
#?                    <input id="TAG-EVENT0" type="checkbox"> EVENT </label>
#?               <label id="l-TAG-EVENT...
#?          </fieldset></div>
#?
#?      or:
#?
#?          <body> ...
#?          <div><fieldset><span> <TAG> </span>
#?               <TAG id="TAG"\
#?                 EVENT0="return $e$(this,'EVENT0');"
#?                 EVENT1="return $e$(this,'EVENT1');"
#?                 EVENT...
#?               >-test me-</TAG>
#?               <label id="l-TAG-EVENT0">\
#?                    <input id="TAG-EVENT0" type="checkbox"> EVENT </label>
#?               <label id="l-TAG-EVENT...
#?          </fieldset></div>
#?
#? LIMITATIONS
#?      Following limitations exists (4/2020):
#?      *  parent|child no checks are done, if a tag is valid in the generated
#?                      HTML content (see DESCRIPTION of content above).
#?      *  multiple tags    in the <head> section,  a tag may occour more than
#?                      once, this is considered valid HTML content.
#?      *  <html> tag   printed inside <body> tag (works for most Mozilla).
#?      *  <title> tag  (if required) printed twice in <head> section.
#?      *  <meta> tag   printed in <head> section only.
#?      *  <script> tag printed in <body> section only.
#?      *  <script> tag does not contain a type= attribute.
#?      *  <style> tag  does not contain a type= attribute.
#?      *  <body> tag   not yet implemented.
#?      *  <form> tag   printed nested in <body> section, it's a bug here.
#?      *  <noframes> tag   printed in <body> section, it's a bug here.
#?      *  <invalid> tag    any string can be used to generate the content, it
#?                      then will be treated as tag name  and printed like any
#?                      valid tag name, consider this a feature ;-)
#?
# Hacker's INFO
#       The HTML tags and all known tag attributes are not defined herein  but
#       will be extraced from  emir.html  (which serves as master).
#       Following markers are expected in emir.html:
#           emir__HEAD__
#           emir__TITLE__
#           emir__META__
#           emir__EVENTS__
#           emir__TAGS__
#           emir__CHECK__
#           emir__FIELDSET__
#           emir__BODY__
#           emir__JS__
#       not yet used:
#           emir__CSS__
#
# http://en.wikipedia.org/wiki/DOM_events
# http://www.w3.org/TR/2007/WD-DOM-Level-3-Events-20071221/events.html#event-mousemultiwheel
# http://www.slideshare.net/guestb0af15/syngresscrosssitescriptingattacksxssexploitsanddefensemay2007
#
#? EXAMPLES
#?      $0 link > emir-link.html
#?
#?      Please use make to see which files to be generated and how to do it:
#?      make
#?      make all -n
#?      make all
#?
#? SEE ALSO
#?      emir.html
#?
#? VERSION
#?      @(#) tags.pl 1.13 20/06/01 00:01:15
#?
#? AUTHOR
#?      09-dec-09 Achim Hoffmann
#?
# -----------------------------------------------------------------------------

use strict;
use warnings;

## no critic qw(Subroutines::ProhibitSubroutinePrototypes)
#     because we believe that Perl's prototypes make the code better readable
## no critic qw(RegularExpressions::RequireExtendedFormatting)
#     because most used RegEx are simple and easy to understand by humans
## no critic qw(BuiltinFunctions::RequireBlockGrep)
#     grep is not used in "expression form" but in "function form", hence it
#     is good to read by humans (and not awkward as perlcritic states)
## no critic qw(InputOutput::RequireBriefOpen)
#     perlcritic is tooo picky

# --------------------------------------------- internal variables; defaults
my @events;     # from emir.html
my @tags_all;   # from emir.html
my @tags;       # from arguments
my $html;       # from emir.html
my $script;     # from emir.html

my $dbx         = '';   # 'tty' or 'html'
my $emir_js     = 0;    # 1: only print JavaScript content of emir.html

my @input_type  = qw(button hidden text reset submit file checkbox radio); # TODO: not yet implmented

# siehe emir.html "var tags = {}"
my @tags_file   = qw(applet base body form frame frameset head html iframe link meta noembed noframes noscript style title);
my @tags_meta   = qw(base head isindex link meta style title);
my @tags_nouse  = qw(applet body elements); # TODO: not yet implmented
my @tags_attr   = qw(); # TODO
my @tags_empty  = qw(area base basefont br col embed frame hr img input isindex keygen link meta param source spacer track wbr);
my @tags_notext = qw(hr script);            # done by @tags_empty implicitely
my @tags_action = qw(form isindex);         # TODO: not yet implmented
my @tags_input  = qw(button input);         # TODO: not yet implmented
my @tags_table  = qw(table tbody thead tfoot caption col colgroup tr td th);
my @tags_select = qw(multicol optgroup option select); # TODO: not yet implmented

my @tags_lists  = qw(ol ul);                # not yet used
my @tags_width10= qw(applet embed iframe);
my @tags_check; # contains the tags which need an additional fieldset with
                # checkboxes for the events in the <body> part, added dynamically

# --------------------------------------------- functions
sub _dbx_tty($) { my $t=shift; $t=~s/--/−−/g; print STDERR "#[$0]: $t\n"; return; }
sub _dbx_html($){ my $t=shift; $t=~s/--/−−/g; print "<!-- $t -->\n"; return; }
sub _dbx($)     {
	#? print line as HTML comment for debugging; replace -- by 2 "minus sign"s \u2212
	if ('tty'  eq $dbx) { _dbx_tty  shift; }
	if ('html' eq $dbx) { _dbx_html shift; }
	return;
}; # _dbx

sub get_data()  {
	#? extract data from emir.html: @events, @tags_all, $html, $script
	#
	# extraction expects well formed data in  emir.html, following formats
	# are expected:
	#   var events = {
	#       'all': { //# __EVENTS__
	#           'event0': any other text
	#           'eventX': ...
	#           ...
	#       }, // all //# __EVENTS__
	#   }; // events
	#   var tags = {
	#       'HTML 4': { //# __TAGS__
	#           'tag0': any other text
	#           'tagX': ...
	#           ...
	#       }, // HTML 4 //# __TAGS__
	#   }; // tags
	# First word (usualy enclosed in') of each line betwwen emir__EVENTS__
	# and emir__TAGS__ will be extracted and added to the corresponding array.
	#
	binmode(STDOUT, ":encoding(UTF-8)");
	my $f   = './emir.html';
	my $fh;
	open($fh, '<:encoding(UTF-8)', $f) || die "$0: WARNING: cannot read »$f«.\n";
	my $mode = 'skip';
	my $js   = 0;
	while(<$fh>) {
		/^\s*.*emir__JS__/          && do { $js = not $js; next; };
		if ($js) {
			$script .= $_ ;
		} else{
			$html   .= $_  ;
		}
		/^\s*#/           && next;  # comments: lazy match, but good enough
		/^\s*\/\//        && next;  # ...
		/^\s*\/\*/        && next;  # ...
		/^\s*\*\/\s*$/    && next;  # ...
		/^\s*'all'.*emir__EVENTS__/ && do { $mode = 'events'; next; };
		/^\s*'HTML .'.*emir__TAGS__/&& do { $mode = 'tags';   next; };
		/^\s*}.*emir__/             && do { $mode = 'skip';   next; };
		next if 'skip' eq $mode;
		my $arg =  $_;
		   $arg =~ s/\s*'([^']*)'.*$/$1/s; # extract left-most word which is enclosd in '
		if ('events' eq $mode) {
			# 5/2020: content in emir.html changed: events are no
			# longer listed in events[all] but in all other hashes
			# so only the event definition needs to be extracted,
			# they all have the value null
			# TODO: extracts also strings inside /* .. */ comments
			next if $_ !~ m/^\s*'.*?null.*/;
			next if (grep(/^$arg$/, @events)); # ignore duplicates
		}
		push(@events,   $arg) if 'events' eq $mode;
		push(@tags_all, $arg) if 'tags'   eq $mode;
	}
	close($fh);
	return;
}; # get_data

sub p_event($)  { my $evt=shift; my $e='$e$'; return "$evt=\"return $e(this,'$evt');\""; }
sub p_events()  { my $ret; $ret .= "\n\t\t" . p_event($_) foreach (@events); return $ret; }
sub p_input($)  { return '<input type="checkbox" disabled="1" ' . "id=$_[0] name=$_[0] />"; }
	# Note that input tag is disabled to avoid that manual clicking the checkbox
	# itself changes the value

sub p_checkbox($$)  {
	#? return checkbox tag with label: <label><input type=checkbox ></label>
	my $tag = shift;
	my $evt = shift;
	my $display = '"display:none"';
	my $label_id= '"l-' . qq($tag-$evt) . '"';  # avoid \" in string concatenation
	my $input_id= '"'   . qq($tag-$evt) . '"';
	return "\t<label id=$label_id style=$display >| " .
		p_input($input_id) .
		"$evt</label>\n";
}; # p_checkbox

sub p_checkboxes($) {
	#? return checkbox tags for all known events
	my $tag = shift;
	my $ret = '';
	foreach my $evt (@events) { $ret .= ' ' . p_checkbox($tag, $evt); }
	return $ret;
}; # p_checkboxes

sub p_tag($$$$)     {
	#? return tag: <tag events ...>-test-me- </tag>
	my $tag = shift;
	my $id  = shift;
	my $txt = shift;
	my $end = shift;# print </tag> (currently only required for <head>
	# according https://www.w3.org/TR/xhtml1/  empty (aka standalone) tags
	# must be written as  <tag /> or <tag></tag>  and must not contain any
	# text; the short notation  <tag />  is used here
	return  "\t<$tag id=\"$id\" name=\"$id\"" .
		((grep(/^$tag$/, @tags_width10)) ? ' width="15" height="15" ' : '') .
		p_events() .
		((grep(/^$tag$/, @tags_empty))   ? ' />' : ">$txt") .
		(($end==1) ? "\n\t</$tag>" : '') .
		"\n";
}; # p_tag

sub p_fieldset($$)  {
	#? return tag: <tag events ...>-test-me- </tag>
	my $tag = shift;
	my $see = shift; # 0: no tag with "-test-me-; 1: with tag
	#my $chk = shift; # 0: no checkbox tags; 1: checkbox tag for each event
	my $chk = 1;
	return  "    <div><fieldset><span>&#xff1c;" . uc($tag) . "&#xff1e;</span>\n" .
		(($see==1) ? p_tag($tag, $tag, '-test me-', 1) : '') .
		(($chk==1) ? p_checkboxes($tag)                : '') .
		"    </fieldset></div>\n\n";
}; # p_fieldset

sub p_frameset($)   {
	#? return frameset: <tag events ...>-test-me- </tag>
	#  can be used for frame and frameset tag
	my $tag = shift;
	#
	# frame and frameset tags are a bit tricky, 'cause they are not inside
	# <body> and do not allow other usual HTML tags, hence everything must
	# be content of an (other) frame. The frames do not use their own file
	# here, but all content as inline HTML in the src= attribute. Therfore
	# following substitues in the inline HTML are necessary:
	#    '      must be replaced because they are needed where " are used
	#    "      must be replaced by ' because HTML can't escape quotes
	#    &#x3c  HTML entity must be replaced by another charcter
	#    &#x3e  HTML entity must be replaced by another charcter
	#    HTML entities in  src="data:text/html,..." are substituded before
	#           rendered,  hence they cannot be used  to escape their meta
	#           functionality
	# The attribute  src="data:text/html;charset=UTF-8, ..."  must be used
	# because unicode characters are used in the inline HTML.
	# For these substitutes see  $checkboxes  below.
	# The checks for the frame and frameset tag are similar, the generated
	# HTML is very similar too, example:
	#
	#    <-- example for frameset -->
	#    <frameset rows="50,50,*" id="frameset" 
	#        	-- list of event attributes --  >
	#        <frame id="check" src=" -- HTML with checkboxes --" />
	#        <frame id="dummy" src=" -- dummy HTML --" />
	#    </frameset>
	#
	#    <-- example for frame -->
	#    <frameset rows="50,50,*" id="frameset" >
	#        <frame id="frame-f" name="frame-f" 
	#        	-- list of event attributes -- />
	#        <frame id="check" src=" -- HTML with checkboxes --" />
	#        <frame id="dummy" src=" -- dummy HTML --" />
	#    </frameset>
	#
	my $checkboxes  =  p_fieldset($tag, 0); # frame containing the checkboxes
	   $checkboxes  =~ s#\n##g;         # remove \n
	   $checkboxes  =~ s#'#/#g;         # TODO: to be tested
	   $checkboxes  =~ s#"#'#g;
	my $frame_dummy = '<frame id="dummy" src="data:text/html,<html><body><h3>just a dummy frame</h3></body></html>" />';
	my $frame_check = '<frame id="check" src="data:text/html;charset=UTF-8,<html><body>_CHECKS_</body></html>" />';
	   $frame_check =~ s/_CHECKS_/$checkboxes/;
	my $noframes    = '<noframes>Browser does not support frames.</noframes>';
	my $frame       = p_events() . " >-test me-\n";       # code for frameset
	if ($tag =~ m/^frame$/i) {
	   $frame       = " >\n" . p_tag($tag, "$tag-f", '', 1); # code for frame
		# close frameset tag and add frame tag with events
	}
	return '<frameset rows="50,50,*" id="frameset"' . 
		$frame .
		"\t$frame_check\n" .
		"\t$frame_dummy\n" .
		"</frameset>\n$noframes\n</html>\n";
}; # p_frameset

sub uniq {
    my %seen;
    return grep !$seen{$_}++, @_;
}

# --------------------------------------------- options
while ( $#ARGV >= 0 ) {
	my $arg = shift;
	if ($arg =~ m/--js/)              { $emir_js = 1;  next; }
	if ($arg =~ m/--dbx.?html/)       { $dbx = 'html'; next; }
	if ($arg =~ m/--debug.?html/)     { $dbx = 'html'; next; }
	if ($arg =~ m/--d(bx|ebug).?tty/) { $dbx = 'tty';  next; }
	if ($arg =~ m/--d(bx|ebug)?/)     { $dbx = 'tty';  next; }
	if ($arg =~ m/--?h(elp)?/) {
		my $me  = $0; $me   =~ s#.*[/\\]##;
		my $fh;
		binmode(STDOUT, ":encoding(UTF-8)");
		open($fh, '<:encoding(UTF-8)', $0) || die "$0: WARNING: cannot read myself.\n";
		while(<$fh>) {
			s/\$0/$me/g;
			/^#\?(.*)$/     && print "$1\n";
		}
		close($fh);
		exit(2);
	}
	push(@tags, $arg);
}

# --------------------------------------------- main
#
# generate code for required tags and corresponding checkboxes
# then insert generated code in proper positions in emir.html
# all the positions are marked with  emir__*__  comments, they
# simply replaced with the generated code
get_data();
if (0 < $emir_js) {
	print $script;
	exit 0;
}
$script   = '<script type="text/javascript">var emir_file=true;</script>';
	# generated files do not use inline JavaScript, therfore emir_file=true;
	# must be defined in its own script tag

@events   = uniq(@events);
@tags_all = uniq(@tags_all);
$html     =~ s/^<!--.*-->$//m;   # TODO:  remove initial comments, useless here
$html     =~ s#^(\s*<script .*)>#\t$script$1 src="emir.js" >#m;
my $tag_html    = '';
my $tag_end     = 1;
my $tag_noend   = 0;
my $tag_testme  = 1;
my $tag_notestme= 0;
my $code  = '';
my $meta  = '';

_dbx "<head> tag";
if (grep(/^head$/, @tags)) {
	$code =  p_tag('head', 'head', $tag_html, $tag_noend);
	$html =~ s/^\s*<head>.*emir__HEAD__\s*-->/$code/m;
	push(@tags_check, 'head');
}

_dbx "tags inside <head>";
foreach my $tag (@tags) {
	next if ($tag =~ /^head$/);# already done
	next if (!grep(/^$tag$/, @tags_meta));
	$code =  p_tag($tag, $tag, $tag_html, $tag_end);
	if ($tag =~ /^title$/) {   # fix visible text
		$code =~ s#(</title>)#EMiR - Event Mappings in Reality (tags.pl 1.13)$1#;
		$html =~ s/^\s*<title>.*emir__TITLE__\s*-->//m; # remove original
	}
	$meta .= $tag;
	push(@tags_check, $tag);
	# p_fieldset() also generates the checkboxes used by the events, but as
	# this is outside the  <body> tag, they are not visible and most likely
	# not accessable using JavaScript's DOM. The checkboxes must be created
	# in the body part of the content again, that's why @tags_check is set.
}
$html =~ s/^\s*<meta.*emir__META__\s*-->/$code/m if ('' ne $meta);

_dbx "<frame*> tag";
$code = '';
foreach my $tag (@tags) {
	next if (!grep(/^$tag/, 'frameset'));
	# TODO: code only works as expected only with a single frame* argumnet
	# frame or frameset requires the same scope, but no other tags
	# hence just the <frameset> scope is printed and then exits
	$code = p_frameset($tag);
	$html =~ s#^\s*<body.*{ //. emir__META__.*} //. emir__BODY__ -->#$code#m;
	print $html;
	exit;
}

_dbx "checkboxes -- for tags inside <head>";
$code = '';
foreach my $tag (@tags_check) {
	$code .= p_fieldset($tag, $tag_notestme);
}
$html =~ s/^\s*<!--.*emir__CHECK__\s*-->/$code/m if ('' ne $code);

_dbx "tags inside <body>";
$code = '';
foreach my $tag (@tags) {
	next if (grep(/^$tag$/, @tags_meta));
	$code .= p_fieldset($tag, $tag_testme);
}
$html =~ s/^\s*<!--.*emir__FIELDSET__\s*-->/$code/m if ('' ne $code);

# <plaintext> is obsolte, has no end-tag
if (1==2) {
	local $\ = "\n";
	my $tag = 'plaintext';
	print '';
	print '<div><fieldset><span>&#x3c;', $tag, ' LI&#x3e;</span>';
	print '   <', $tag, ' id="', $tag, '"';
	foreach my $evt (@events) { print ' ', p_event($evt); }
	print ">\n";
}

print $html;

exit;

__END__

# following data just as reminder/example (as used in emir.html 1.42)

my %events_all = (
	# note that spelling (case) must be identical in all hashes
	'DOMContentLoaded'     => 'null',
	'DOMFrameContentLoaded'=> 'null',
	'DOMMouseScroll'       => 'null',
	'DOMMenuItemActive'    => 'null',
	'DOMMenuItemInactive'  => 'null',
	'FSCommand'            => 'null', # SWF only
	'formchange'           => 'null', # typo? Opera
	'forminput'            => 'null', # typo? Opera
	'invalid'              => 'null', # typo? Opera
	'msVisibilityChange'   => 'null', # IE9 ??
	'onAbort'              => 'null',
	'onActivate'           => 'null',
	'onAfterPrint'         => 'null',
	'onAfterUpdate'        => 'null',
	'onAttrModified'       => 'null', # typo?
	'onAfterScriptExecute' => 'null', # Firefox >= 4
	'onBack'               => 'null',
	'onBeforeActivate'     => 'null',
	'onBeforeCopy'         => 'null',
	'onBeforeCut'          => 'null',
	'onBeforeDeactivate'   => 'null',
	'onBeforeEditFocus'    => 'null',
	'onBeforePaste'        => 'null',
	'onBeforePrint'        => 'null',
	'onBeforeScriptExecute'=> 'null', # Firefox >= 4
	'onBeforeUnload'       => 'null',
	'onBeforeUpdate'       => 'null',
	'onBegin'              => 'null',
	'onBlur'               => 'null',
	'onBounce'             => 'null',
	'onBroadcast'          => 'null',
	'onCanPlay'            => 'null',
	'onCanPlayThrough'     => 'null',
	'onCellChange'         => 'null',
	'onChange'             => 'null',
	'onCharacterDataModified'  => 'null', # typo?
	'onClick'              => 'null',
	'onClose'              => 'null',
	'onCommand'            => 'null',
	'oncontentsave'        => 'null', # case-sensitive (IE)
	'oncontentready'       => 'null', # case-sensitive (IE)
	'onCommandUpdate'      => 'null',
	'onContextMenu'        => 'null',
	'onControlSelect'      => 'null',
	'onCopy'               => 'null',
	'onCut'                => 'null',
	'onDataAvailable'      => 'null',
	'onDataSetChanged'     => 'null',
	'onDataSetComplete'    => 'null',
	'onDblClick'           => 'null',
	'onDeactivate'         => 'null',
	'ondetach'             => 'null', # case-sensitive (IE)
	'ondocumentready'      => 'null', # case-sensitive (IE)
	'onDOMActivate'        => 'null',
	'onDOMAttrModified'    => 'null',
	'onDOMAttributeNameChanged'    => 'null',
	'onDOMCharacterDataModified'   => 'null',
	'onDOMElementNameChanged'      => 'null',
	'onDOMFocusIn'         => 'null',
	'onDOMFocusOut'        => 'null',
	'onDOMNodeInserted'    => 'null',
	'onDOMNodeInsertedIntoDocument'=> 'null',
	'onDOMNodeRemoved'     => 'null',
	'onDOMNodeRemovedFromDocument' => 'null',
	'onDOMSubTreeModified' => 'null',
	'onDrag'               => 'null',
	'onDragDrop'           => 'null',
	'onDragEnd'            => 'null',
	'onDragEnter'          => 'null',
	'onDragExit'           => 'null',
	'onDragGesture'        => 'null',
	'onDragLeave'          => 'null',
	'onDragOver'           => 'null',
	'onDragStart'          => 'null',
	'onDrop'               => 'null',
	'onDurationChange'     => 'null',
	'onEmtied'             => 'null',
	'onEnded'              => 'null',
	'onEnd'                => 'null',
	'onError'              => 'null',
	'onErrorUpdate'        => 'null',
	'onExit'               => 'null',
	'onFilterChange'       => 'null',
	'onFinish'             => 'null',
	'onFocus'              => 'null',
	'onFocusIn'            => 'null',
	'onFocusOut'           => 'null',
	'onFormChange'         => 'null',
	'onFormInput'          => 'null',
	'onForward'            => 'null',
	'ongesturechange'      => 'null',
	'ongestureend'         => 'null',
	'ongesturestart'       => 'null',
	'onHashChange'         => 'null',
	'onHelp'               => 'null',
	'onhide'               => 'null', # case-sensitive (IE)
	'onInput'              => 'null',
	'onInvalid'            => 'null',
	'onKeyDown'            => 'null',
	'onKeyPress'           => 'null',
	'onKeyUp'              => 'null',
	'onLayoutComplete'     => 'null',
	'onLoad'               => 'null',
	'onLoadedData'         => 'null',
	'onLoadedMetaData'     => 'null',
	'onLoadStart'          => 'null',
	'onLocate'             => 'null',
	'onLoseCapture'        => 'null',
	'onMediaComplete'      => 'null',
	'onMediaError'         => 'null',
	'onMessage'            => 'null',
	'onMouseDown'          => 'null',
	'onMouseDrag'          => 'null',
	'onMouseEnter'         => 'null',
	'onMouseLeave'         => 'null',
	'onMouseMove'          => 'null',
	'onMouseMultiWheel'    => 'null',
	'onMouseOut'           => 'null',
	'onMouseOver'          => 'null',
	'onMouseUp'            => 'null',
	'onMouseWheel'         => 'null',
	'onmove'               => 'null', # case-sensitive (IE)
	'onMoveEnd'            => 'null',
	'onMoveStart'          => 'null',
	'onmsGestureChange'    => 'null', # IE9 ??
	'onmsGestureDoubleTap' => 'null', # IE9 ??
	'onmsGestureEnd'       => 'null', # IE9 ??
	'onmsGestureHold'      => 'null', # IE9 ??
	'onmsGestureStart'     => 'null', # IE9 ??
	'onmsGestureTap'       => 'null', # IE9 ??
	'onmsSiteModeJumpListitemRemoved' => 'null',  # IE9 ??
	'onmsSiteModeShowJumpList'        => 'null',  # IE9 ??
	'onmsThumbnailClick'   => 'null', # IE9 ??
	'onNodeInserted'       => 'null', # typo?
	'onNodeRemoved'        => 'null', # typo?
	'onOffline'            => 'null',
	'onOnline'             => 'null',
	'onopenstatechanged'   => 'null', # case-sensitive (IE)
	'onorientationchange'  => 'null',
	'onOutOfSync'          => 'null',
	'onOverFlow'           => 'null',
	'onOverFlowChanged'    => 'null',
	'onPage'               => 'null',
	'onPageHide'           => 'null',
	'onPageShow'           => 'null',
	'onPaste'              => 'null',
	'onPause'              => 'null',
	'onPlay'               => 'null',
	'onPlaying'            => 'null',
	'onplaystatechange'    => 'null', # case-sensitive (IE)
	'onPopState'           => 'null',
	'onPopupHidden'        => 'null',
	'onPopupHiding'        => 'null',
	'onPopupShowing'       => 'null',
	'onPopupShown'         => 'null',
	'onProgress'           => 'null',
	'onPropertyChange'     => 'null',
	'onRateChange'         => 'null',
	'onReadyStateChange'   => 'null',
	'onRedo'               => 'null',
	'onRepeat'             => 'null',
	'onReset'              => 'null',
	'onResize'             => 'null',
	'onResizeEnd'          => 'null',
	'onResizeStart'        => 'null',
	'onResume'             => 'null',
	'onReverse'            => 'null',
	'onRowDelete'          => 'null', # typo?
	'onRowEnter'           => 'null',
	'onRowExit'            => 'null',
	'onRowInserted'        => 'null', # typo?
	'onRowsDelete'         => 'null',
	'onRowsInserted'       => 'null',
	'onSave'               => 'null',
	'onScroll'             => 'null',
	'onSearch'             => 'null',
	'onSeek'               => 'null',
	'onSeeked'             => 'null',
	'onSeeking'            => 'null',
	'onSelect'             => 'null',
	'onSelection'          => 'null', # iOS
	'onSelectionChange'    => 'null',
	'onSelectStart'        => 'null',
	'onShow'               => 'null',
	'onStalled'            => 'null',
	'onStart'              => 'null',
	'onStop'               => 'null',
	'onStorage'            => 'null',
	'onStorageCommit'      => 'null',
	'onSubmit'             => 'null',
	'onSubTreeModified'    => 'null', # typo?
	'onSuspend'            => 'null',
	'onSyncRestored'       => 'null',
	'onSynchRestored'      => 'null', # typo?
	'onText'               => 'null',
	'onTextInput'          => 'null',
	'onTimeError'          => 'null',
	'onTimeuout'           => 'null',
	'onTimeupdate'         => 'null',
	'ontouchcancel'        => 'null', # iOS
	'ontouchend'           => 'null', # iOS
	'ontouchenter'         => 'null',
	'ontouchmove'          => 'null', # iOS
	'ontouchleave'         => 'null',
	'ontouchstart'         => 'null', # iOS
	'onTrackChange'        => 'null',
	'onUnderflow'          => 'null',
	'onUndo'               => 'null',
	'onUnload'             => 'null',
	'onURLFlip'            => 'null',
	'onVolumeChange'       => 'null',
	'onWaiting'            => 'null',
	'onWheel'              => 'null', # Firefox >= 4
	'onXfer_Done'          => 'null',
	'onwebkitanimationend'         => 'null',
	'onwebkitanimationiteration'   => 'null',
	'onwebkitanimationstart'       => 'null',
	'onwebkittransitionend'        => 'null',
	'seekSegmentTime'      => 'null'
);

my @tags4  = qw(
	a
	abbr
	acronym
	address
	applet
	area
	audioscope
	b
	base
	basefont
	bdo
	bgsound
	big
	blackface
	blink
	blockquote
	-body
	bq
	br
	button
	caption
	center
	cite
	code
	col
	colgroup
	comment
	dd
	del
	dfn
	dir
	div
	dl
	dt
	em
	elements
	fieldset
	fn
	font
	form
	frame
	frameset
	h1
	head
	hr
	html
	i
	iframe
	ilayer
	img
	input
	ins
	isindex
	kbd
	label
	layer
	legend
	-li
	limittext
	link
	listing
	map
	marquee
	meta
	multicol
	nextid
	nobr
	noframes
	noscript
	object
	ol
	optgroup
	option
	p
	param
	-plaintext
	pre
	q
	s
	samp
	script
	select
	server
	shadow
	sidebar
	small
	spacer
	span
	strike
	strong
	style
	sub
	sup
	table
	tbody
	td
	textarea
	tfoot
	th
	thead
	title
	tr
	tt
	u
	ul
	var
	wbr
	xml
	xmp
);
my @tags5  = qw(
	article
	aside
	bdi
	canvas
	command
	datalist
	dialog
	details
	embed
	figcaption
	figure
	footer
	header
	hgroup
	keygen
	mark
	menu
	meter
	nav
	noembed
	nosmartquotes
	progress
	output
	rp
	rt
	ruby
	section
	source
	summary
	time
	track
	video
);

