import flag
import os

struct Rules {
}

struct Args {
	directory string = os.getwd() @[short: C]
	jobs int = 1 @[short: j]
}

pub fn (args Args) execute_rule(rule string) ! {
	if args.directory != os.getwd() {
		os.chdir(args.directory) or {
			return error("vmake: *** Can not change directory. Stop.")
		}
	}
	rules := Rules{}
	$for method in Rules.methods {
		if method.name == rule {
			rules.$method(args) or {
				return error('vmake: *** [${rule}] Error:\n${err}')
			}
			return
		}
	}
	return error("vmake: *** No rule to make target '${rule}'.  Stop.")
}

fn main() {
	args, no_matches := flag.using[Args](Args{}, os.args, skip: 1) or {
		eprintln('ERROR: ${err}')
		doc := flag.to_doc[Args]() or {
			eprintln('vmake: *** For some reason when creating the documentation')
			exit(2)
		}
		eprintln(doc)
		exit(2)
	}
	for rule in no_matches {
		args.execute_rule(rule) or {
			eprintln(err)
			exit(2)
		}
	}
}

fn (r Rules) all(args Args) ! {
	args.execute_rule('target')!
}

fn (r Rules) target(args Args) ! {
	println('Building project!')
	return error('Error foo bar')
}
