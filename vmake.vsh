import flag
import os

struct Rules {
}

struct Args {
	directory string = os.getwd() @[short: C]
	jobs      int    = 1    @[short: j]
}

pub fn (args Args) execute_rule(rule string) ! {
	if args.directory != os.getwd() {
		os.chdir(args.directory) or { return error('vmake: *** Can not change directory. Stop.') }
	}
	rules := Rules{}
	$for method in Rules.methods {
		if method.name == rule {
			rules.$method(args) or { return error('vmake: *** [${rule}] Error:\n${err}') }
			return
		}
	}
	return error("vmake: *** No rule to make target '${rule}'.  Stop.")
}

pub fn (args Args) check_deps_updated(output string, deps []string) bool {
	mut output_stat := os.Stat{}
	$if windows {
		output_stat = os.lstat(output) or { os.lstat(output + '.exe') or { return true } }
	} $else {
		output_stat = os.lstat(output) or { return true }
	}
	output_mtime := output_stat.mtime
	for dep in deps {
		mut dep_stat := os.Stat{}
		$if windows {
			dep_stat = os.lstat(dep) or { os.lstat(dep + '.exe') or { return true } }
		} $else {
			dep_stat = os.lstat(dep) or { return true }
		}
		dep_mtime := dep_stat.mtime
		println('${dep_mtime} ${output_mtime}')
		if dep_mtime > output_mtime {
			return true
		}
	}
	return false
}

pub fn (args Args) execute_shell(cmd string) ! {
	println(cmd)
	res := os.execute_opt(cmd)!
	print(res.output)
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
	if !args.check_deps_updated('vmake', ['vmake.v']) {
		return
	}
	args.execute_shell(@VEXE + ' -prod .')!
}

fn (r Rules) fmt(args Args) ! {
	args.execute_shell(@VEXE + ' fmt -w .')!
}
