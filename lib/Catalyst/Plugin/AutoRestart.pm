package Catalyst::Plugin::AutoRestart;

use strict;
use warnings;
use Class::C3;
use Text::SimpleTable;
use Proc::ProcessTable;

our $VERSION = '0.91';

=head1 NAME

Catalyst::Plugin::AutoRestart - Catalyst plugin to restart every 'n' requests

=head1 SYNOPSIS

use Catalyst qw/AutoRestart/;

 __PACKAGE__->config->{Plugin::AutoRestart} = {
	active => '1',
	check_each => '20',
	max_bits => 576716800,
	min_handled_requests => '150',
 }

 <Plugin::AutoRestart>
    active   1
    check_each   20
    max_bits  576716800
    min_handled_requests   150
 </Plugin::AutoRestart>

=head1 DESCRIPTION

Catalyst plugin to force the application to restart after a configurable number
of requests handled.  This is intended as a bandaid to deal with problems like
memory leaks; it's here to buy you time to find and solve the underlying issues.

=head1 CONFIGURATION

=head2 active 

This is used to turn the plugin on and off 

=head2 check_each 

This is the number of requests to wait between checks 

=head2 min_handled_requests

Minimum application requests before process size check starts occurring. 
This is to prevent your application processes from exiting immediately in 
case your application is bigger than your max_bits limit.  

The default is 500 requests

=head2 max_bits

This is the size virtual memory can grow to before triggering a restart

The default is 524288000 bits (500 mb)


=head1 SEE ALSO

For trying to solve memory leaks see L<Devel::Leak::Object>

=head1 EXTENDED METHODS

The following methods are extended from the main Catalyst application class.

=head2 setup

Create sane defaults

=cut

sub setup {
	my $c = shift @_;
	my $config = $c->config->{'Plugin::AutoRestart'} || {};

	$config->{_process_table} = Proc::ProcessTable->new;
    
	$config->{max_bits} = 524288000
	 unless $config->{max_bits}; ## 500 megabit is the default

	$config->{min_handled_requests} = 500 
	 unless $config->{min_handled_requests}; 

    return $c->next::method(@_)
}

=head2 handle_request

Count each handled request and when a threshold is met, restart.

=cut

sub handle_request {
	my ($c, @args) = (shift,  @_); 
	my $ret = $c->next::method(@args);
	my $config = $c->config->{'Plugin::AutoRestart'} || {};
	    
	return $ret
	 unless $config->{active};
	 
	my $check_each = $config->{check_each};
     
	if($Catalyst::COUNT > $config->{min_handled_requests}){
		if ($Catalyst::COUNT/$check_each == int($Catalyst::COUNT/$check_each)) { 
			$c->log->warn('Checking Memory Size.');

			my $size = $c->_debug_process_table($c);
			
			$c->log->warn("Found size is $size");
			
			if(defined $size && $size > $config->{max_bits} ) {
				# this actually wont output to log since it exits
				$c->log->warn("$size is bigger than: ".$config->{max_bits}. "exiting now...");
				exit(0);
			}
		}
	}
 
    return $ret;
}


=head2 _debug_process_table

Send to the log the full running process table

=cut

sub _debug_process_table {
	my ($c) = @_;
	my $config = $c->config->{'Plugin::AutoRestart'} || {};
	
	foreach my $p ( @{$config->{_process_table}->table} ) {
		next
		 unless $p->pid == $$;
		 
		my $table = new Text::SimpleTable( [ 6, 'PID' ], [ 12, 'VIRT' ], [ 12, 'RES' ], [ 15, 'COMMAND' ] );
		$table->row($p->pid, $p->size, $p->rss, $p->cmndline);
		$c->log->warn("Process Info:\n" . $table->draw);
		
		return $p->size;
	}
	return;
}


=head1 AUTHORS

 John Napiorkowski <john.napiorkowski@takkle.com>
 John Goulah       <jgoulah@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut

1;
