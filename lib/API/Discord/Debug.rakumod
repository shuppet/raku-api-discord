use v6.d;

=begin pod

Debug output is silent by default. A user can activate it with:

    use API::Discord::Debug;

Any module that want to output to $*STDERR can do so with:

    use API::Discord::Debug <FROM-MODULE>

The subs C<debug-print> and C<debug-say> forward arguments to C<$*ERR.print>
and C<$*ERR.say>.

Debug output can be diverted to C<Supply>s of C<Str> with mixin roles for
filtering.

    use API::Discord::Debug;

    react whenever debug-say().merge(debug-print()) {
        when HEARTBEAT { $*ERR.print: $_ }
        when CONNECTION { note now.Datetime.Str, ' ', $_ }
        when /your term here/ { .&do-stuff() }
        default {}
    }

The sub C<debug-say-logfile> diverts output to a C<IO::Path> and forwards named
arguments to C<IO::Handle.open>.

    use API::Discord::Debug;
    debug-say-logfile('/tmp/discord-bot-logfile.txt', :append);
    react whenever debug-print() {
        default {}
    }

=end pod

my $active = False;

sub debug-print(|c) {
    $*ERR.print: |c if $active;
}

sub debug-say(|c) {
    $*ERR.say: |c if $active;
}

sub debug-print-supply(Supply $in? --> Supply:D) {
    my $result = $in // Supplier::Preserving.new;

    &debug-print.wrap(-> |c {
        $result.emit: |c
    });

    $result.Supply
}

sub debug-say-supply(Supply $in? --> Supply:D) {
    my $result = $in // Supplier::Preserving.new;

    &debug-say.wrap(-> |c {
        $result.emit: |c
    });

    $result.Supply
}

sub debug-say-logfile(IO::Path() $path, *%_) {
    my $loghandle = $path.open(|%_);
    &debug-say.wrap(-> |c {
        $loghandle.put: now.DateTime, ' ', |c;
    });
}

multi sub EXPORT('FROM-MODULE') {
    %( 
        '&debug-print' => &debug-print,
        '&debug-say' => &debug-say,
    )
}

multi sub EXPORT() {
    $active = True;

    %(
        '&debug-print' => &debug-print-supply,
        '&debug-say' => &debug-say-supply,
        '&debug-say-logfile' => &debug-say-logfile,
    )
}

role LogEventType is export {}

role CONNECTION does LogEventType is export {}
role WEBSOCKET does CONNECTION is export {}
role HEARTBEAT does WEBSOCKET is export {}
role PING does HEARTBEAT does LogEventType is export {}
role PONG does HEARTBEAT does LogEventType is export {}
