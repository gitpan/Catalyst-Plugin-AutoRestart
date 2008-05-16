use inc::Module::Install '0.68';

name 'Catalyst-Plugin-AutoRestart';
all_from 'lib/Catalyst/Plugin/AutoRestart.pm';

requires 'Catalyst' => '5.7007';
requires 'Class::C3' => '0.19';
requires 'Text::SimpleTable' => '0.03';
requires 'Proc::ProcessTable' => '0.41';

# generate README file
if ($Module::Install::AUTHOR) {
  system('pod2text lib/Catalyst/Plugin/AutoRestart.pm > README');
}

tests_recursive();
auto_install;
WriteAll;

