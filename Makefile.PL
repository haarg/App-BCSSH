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

  PREREQ_PM => {
    'Moo'               => 0,
    'Package::Variant'  => 0,
    'Module::Runtime'   => 0,
    'Try::Tiny'         => 0,
    'Module::Find'      => 0,
    'File::Temp'        => 0.19,
    'IO::Select'        => 0,
    'IO::Socket::UNIX'  => 0,
    'strictures'        => 0,
    'Module::Reader'    => 0,
    'MooX::CaptainHook' => 0,
    'Pod::Simple'       => 0,
    'Pod::Perldoc'      => 0,
    'Browser::Open'     => 0,
    'Safe::Isa'         => 0,
  },

  META_MERGE => {
    requires => {
        perl => '5.8.1',
    },
  },
);
