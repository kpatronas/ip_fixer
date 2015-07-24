#!/usr/bin/env perl
use strict;
use warnings;

my $s_old_octet 		= "";
my $s_new_octet 		= "";
my $s_octet_position 	= "";

($s_old_octet, $s_new_octet, $s_octet_position) = @ARGV;

if (!$s_old_octet || !$s_new_octet)
{
    print "\nUsage: ".$0." old_octet new_octet  [octet_position]\n";
	print "old_octet: The old IP octet value that you want to replace\n";
	print "new_octet: The new IP octet value that you want its value to replace the old_octet value\n";
	print "[OPTIONAL] octet_position, if not given the script will do changes in all octets of found IPs, if given will do changes in ranges only\n";
	print "Example: 2: will do changes in 2nd octet only, 2-3: will do changes in 2nd and 3rd octet only\n";
	print "config.csv contains the directories and files to perform the changes in their IPs\n";
    exit;
}

if ($s_new_octet < 0 || $s_new_octet >255)
{
    print "\nUsage: ".$0." old_octet new_octet  [octet_position]\n";
	print "old_octet: The old IP octet value that you want to replace\n";
	print "new_octet: The new IP octet value that you want its value to replace the old_octet value\n";
	print "[OPTIONAL] octet_position, if not given the script will do changes in all octets of found IPs, if given will do changes in ranges only\n";
	print "Example: 2: will do changes in 2nd octet only, 2-3: will do changes in 2nd and 3rd octet only\n";
	print "config.csv contains the directories and files to perform the changes in their IPs\n";
    exit;
}

my $s_file_source 		= "config.csv";	# The configuration file
my $s_octet_pos_start 	= "";			# The starting octet
my $s_octet_pos_end 	= "";			# The last octet

if($s_octet_position)					# if user has set an octet position, do some validations
{
	($s_octet_pos_start, $s_octet_pos_end) = split('-',$s_octet_position);
	if ($s_octet_pos_start<0 || $s_octet_pos_start>4)
	{
		print "Start position not valid: ".$s_octet_pos_start."\n";
		exit;
	}
	
	if($s_octet_pos_end)
	{
		if ($s_octet_pos_end<0 || $s_octet_pos_end>4)
		{
			print "End position not valid: ".$s_octet_pos_end."\n";
			exit;
		}
	}
	else
	{
		$s_octet_pos_end = $s_octet_pos_start;
	}
}
else
{
	$s_octet_pos_start 	= 1;
	$s_octet_pos_end 	= 4;
}

if ($s_octet_pos_end<$s_octet_pos_start)	# If the user gave the start and stop in the reverse order
{
	($s_octet_pos_start, $s_octet_pos_end) = ($s_octet_pos_end, $s_octet_pos_start);
}

open (my $s_file_source_handler, $s_file_source) or die "Could not open configuration file '$s_file_source' $!";
print "Info: Parsing ".$s_file_source."\n";
my @a_files;

while(my $s_row = <$s_file_source_handler>)					# Loop the configuration file
{
	chomp($s_row);											# Remove the newline
	
	if(-e $s_row)											# if line is an object in the filesystem
	{
		if (-f $s_row)										# if the object is a plain text file
		{
			push(@a_files,$s_row);							# add it in the array of files that we want to check
		}
		if(-d $s_row)										# if the object is a directory
		{
			opendir (DIR, $s_row) or die $!;	
			print "Parsing directory: ".$s_row."\n";
			while (my $file = readdir(DIR))					# iterate inside the directory for each file
			{
				my ($s_ext) = $file =~ /(\.[^.]+)$/;
				next if ($s_ext && $s_ext eq ".bck");		# ignore files with extension of "bck" (backup files)
				my $s_file_to_test;
				if ($^O eq 'MSWin32')						# what if the filesystem is a windows one
				{
					$s_file_to_test = $s_row.'\\'.$file;
				}
				else										# what if the filesystem is not a windows one ;)
				{
					$s_file_to_test = $s_row.'/'.$file;
				}
				if(-f $s_file_to_test)						# Now check if the file is a plain text file, if yes add it to the array
				{
					print "Adding file: ".$s_file_to_test."\n";
					push(@a_files,$s_file_to_test);
				}
			}
		}
	}
	else
	{
		print "Warning: ".$s_row." does not exists\n";
	}
}
			   
my $s_line_text = "";

foreach my $s_file (@a_files)	# For each file
{
	if(-e $s_file)				# Check if the file exists
	{
		open(my $s_filehandler, $s_file) 					or die "Could not open file '$s_file' $!"; 			# Try to open the file or die
		open(my $s_new_filehandler, '>', $s_file.".tmp") 	or die "Could not create file '$s_file'.tmp $!"; 	# Create a new file with the name file plus the .tmp extension							
		print "Info: Parsing ".$s_file."\n";
		
		while (my $s_row = <$s_filehandler>)																	# Read the file line by line until EOF
		{
			$s_line_text = &search_and_modify_ip(line=>$s_row,match=>$s_old_octet,replace=>$s_new_octet);		# The & avoids prototype checking, the function returns a line with the new octed needed
			print $s_new_filehandler $s_line_text;
		}
		
		close $s_filehandler;					# Close the input file
		close $s_new_filehandler;				# Close the output file
		rename $s_file,$s_file.".bck";			# Do the renames
		rename $s_file.".tmp",$s_file;			# Rename again, and job done
	}
	else
	{
		print "Warning: ".$s_file." Does not exist\n";
	}
}

sub search_and_modify_ip()
{
	my %args = @_;																		# Get the named parameters
	my $s_line 		= $args{line};														# Get the line of the file to check of IP addresses
	my $s_match 	= $args{match};														# IP address part to match per subnet
	my $s_replace 	= $args{replace};													# Replace the matching part with this
	
	if ($s_line =~ m/(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})/)						# Ok! we found an IP address
	{
		my $s_line_tmp = $s_line;
		if ($1 <= 255 && $2 <= 255 && $3 <= 255 && $4 <= 255 )							# Its a valid IP address
		{
			my $s_octet_1 = $1;															# Get a copy of the read only values 1st octet
			my $s_octet_2 = $2;															# ... 2nd octet
			my $s_octet_3 = $3;															# ... 3rd octet
			my $s_octet_4 = $4;															# ... 4th octet
			
			$s_octet_1 = $s_replace if (($1 eq $s_match) && (1 >= $s_octet_pos_start && 1<= $s_octet_pos_end));	# Now we check for matches and do replaces per octet (1st Octet)
			$s_octet_2 = $s_replace if (($2 eq $s_match) &&	(2 >= $s_octet_pos_start && 2<= $s_octet_pos_end));	# ... 2nd octet
			$s_octet_3 = $s_replace if (($3 eq $s_match) &&	(3 >= $s_octet_pos_start && 3<= $s_octet_pos_end));	# ... 3rd octet
			$s_octet_4 = $s_replace if (($4 eq $s_match) &&	(4 >= $s_octet_pos_start && 4<= $s_octet_pos_end));	# ... 4th octet
			
			my $s_new_ip 	= $s_octet_1.".".$s_octet_2.".".$s_octet_3.".".$s_octet_4;	# Create the new IP address
			my $s_old_ip 	= $1.".".$2.".".$3.".".$4;									# Hold the old IP address

			$s_line =~ s/$s_old_ip/$s_new_ip/g;
			if ($s_line_tmp ne $s_line)
			{
				print "\told-ip:".$s_old_ip." new-ip:".$s_new_ip."\n";					# Print an informational message
			}
		}
	}
	return $s_line;
}
