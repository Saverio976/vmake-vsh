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

@[deps: 'v.mod	1_args.v	2_main.v	3_rules.v']
@[name: 'vmake']
fn (r Rules) target(args Args) ! {
	args.sh(@VEXE + ' -prod .', timeit: true)!
}

@[phony]
fn (r Rules) fmt(args Args) ! {
	args.sh(@VEXE + ' fmt -w .', timeit: true)!
}
