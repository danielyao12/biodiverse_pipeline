#!/usr/bin/perl -w

use strict;
use warnings;
use 5.010;

use Carp;  #  warnings and dropouts
use English qw ( -no_match_vars );
use Path::Class;


use Biodiverse::BaseData;


#  load up the user defined libs
use Biodiverse::Config;



#############################################
######       SET PARAMETERS HERE       ######


use Getopt::Long::Descriptive;

$| = 1;

#############################################
######       SET PARAMETERS HERE       ######

my ($opt, $usage) = describe_options(
  '%c <arguments>',
  [ 'input_bds_glob|i=s',       'A glob to select which basedata files are loaded.', { required => 0 } ],
  [ 'output_csv_prefix|opfx:s', 'The output biodiverse results file prefix (.csv is appended)'],
  [],
  [ 'help',       'print usage message and exit' ],
);

 
if ($opt->help) {
    print($usage->text);
    exit;
}

my $input_bds_glob    = $opt->input_bds_glob || '*.bds';
my $output_csv_prefix = $opt->output_csv_prefix;

my @bd_files = glob $input_bds_glob;

foreach my $input_bds_file (@bd_files) {
    my $bd;
    eval {
        $bd = Biodiverse::BaseData->new (file => $input_bds_file);
    };
    croak $@ if $@;

    my $file_basename = Path::Class::file($input_bds_file)->basename;

    my @outputs = $bd->get_spatial_output_refs;
    
    foreach my $output (@outputs) {
        my $output_name = $output->get_param('NAME');
        my @lists = $output->get_lists_across_elements;
        foreach my $list (@lists) {
            say $list;
            my $list_fname = $list;
            $list_fname =~ s/>>/--/;  #  systems don't like >> in file names
            my $csv_file = sprintf "%s%s_%s_%s.csv", $output_csv_prefix, $file_basename, $output_name, $list_fname;
            $output->export (
                file   =>  $csv_file,
                format => 'Delimited text',
                list   => $list,
            );
        }
    };

    #  overwrite these for now as we assume they are the same
    my $csv_file = sprintf "%s_%s.csv", $output_csv_prefix, "groups";
    $bd->get_groups_ref->export (
        file   =>  $csv_file,
        format => 'Delimited text',
        list => 'SUBELEMENTS',
    );

}


say 'Process completed';

