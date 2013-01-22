use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

WriteMakefile(
  NAME => 'App::BCSSH',
  VERSION_FROM => 'lib/App/BCSSH.pm',

  EXE_FILES => [
    'bin/bcssh',
  ],

  META_MERGE => {
    requires => {
        perl => '5.8',
    },
  },
);
