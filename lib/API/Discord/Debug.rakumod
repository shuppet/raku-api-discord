use v6.d;

=begin pod

Debug output is silent by default. A user can activate it with:

    use API::Discord::Debug;

Any module that want to output to $*STDERR can do so with:

    use API::Discord::Debug <FROM-MODULE>

The subs C<debug-print> and C<debug-say> forward arguments to C<$*ERR.print>
and C<$*ERR.say>.

=end pod

my $active = False;

sub debug-print(|c) {
    $*ERR.print: |c if $active;
}

sub debug-say(|c) {
    $*ERR.say: |c if $active;
}

multi sub EXPORT('FROM-MODULE') {
    %( 
        '&debug-print' => &debug-print,
        '&debug-say' => &debug-say,
    )
}

multi sub EXPORT() {
    $active = True;

    %()
}
