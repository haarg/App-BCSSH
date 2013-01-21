use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'App-bcssh',
  VERSION_FROM => 'lib/App/bcssh.pm',
  PREREQ_PM => {
    'Moo' => 0,
  },
  LICENSE => 'perl',
);

