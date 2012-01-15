#!/usr/bin/env perl

#
# Submit question to WolframAlpha and print the answer.
#
# Copyright (C) 2012, Lefteris Zafiris <zaf.000@gmail.com>
#
# This program is free software, distributed under the terms of
# the GNU General Public License Version 2. See the COPYING file
# at the top of the source tree.
#
# To use this script you must get an app ID from http://products.wolframalpha.com/api
#
# **This is still very immature code and the output is far from perfect.**
# The script usually prints a single line with the answer or a list of possible answers.
# If you failed to get any results uncomment line 21 and 52, this will print
# a raw output of the data we got from wolfram and might help to find the place where the
# answer is hiding.
#

use strict;
#use warnings;
use LWP::UserAgent;
use CGI::Util qw(escape);
use XML::Simple;
#use YAML;

# Here you can assign your App ID from wolfram #
my $app_id   = "";
my $url      = "http://api.wolframalpha.com/v2/query";
my $question = escape($ARGV[0]);

if (!@ARGV || $ARGV[0] eq '-h' || $ARGV[0] eq '--help') {
	print "Ask WolframAlpha.\n\n";
	print "Usage:   $0 [question]\n\n";
	print "Example: $0 \"What time is it?\"\n";
	exit;
}

my $ua = LWP::UserAgent->new;
$ua->agent("Mozilla/5.0 (X11; Linux) AppleWebKit/535.2 (KHTML, like Gecko)");
$ua->timeout(10);
my $ua_request = HTTP::Request->new(
	'GET' => "$url?input=$question&appid=$app_id&format=plaintext&scantimeout=5&excludepodid=Input&excludepodid=Interpretation"
);
my $ua_response = $ua->request($ua_request);
if (!$ua_response->is_success) {
	print "Failed to contact server.\n";
	exit;
}

my $answer = XMLin($ua_response->content);
if ($answer->{success} eq 'false') {
	print "I don't know how to answer that.\n";
	exit;
}

#print Dump($answer);
my $results = 0;

foreach (keys $answer->{pod}) {
	#print Dump($answer->{pod}->{$_});
	if ($_ eq "subpod") {
		print "$answer->{pod}->{$_}->{plaintext}\n";
		$results++;
		last;
	} elsif ($_ eq "Result") {
		print "$answer->{pod}->{$_}->{subpod}->{plaintext}\n";
		$results++;
		last;
	} elsif ($_ eq "Value") {
		eval{ print "$answer->{pod}->{$_}->{subpod}->{plaintext}\n"; };
		eval{ print "$answer->{pod}->{$_}->{subpod}->[0]->{plaintext}\n"; };
		$results++;
		last;
	}
}
if (!$results) {
	foreach (keys $answer->{pod}) {
		eval{ print "$_: $answer->{pod}->{$_}->{subpod}->{plaintext}\n"; };
		eval{ print "$_: $answer->{pod}->{$_}->{subpod}->[0]->{plaintext}\n"; };
		$results++;
	}
}
print "Failed to get any resutl, possible script bug.\n" if (!$results);
