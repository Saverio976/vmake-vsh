struct Rules {
}

// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------
// End Of License
// ---------------------------------------------------------------------------
// ---------------------------------------------------------------------------

// Write your Rules here:

@[deps: 'vmake']
fn (r Rules) all(args Args) ! {
}

@[deps: 'vmake.v	v.mod']
@[name: 'vmake']
fn (r Rules) target(args Args) ! {
	args.sh(@VEXE + ' -prod .')!
}

@[phony]
fn (r Rules) fmt(args Args) ! {
	args.sh(@VEXE + ' fmt -w .', timeit: true)!
}
