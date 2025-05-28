import flag
import os
import arrays

struct Rules {
}

struct Args {
	directory string = os.getwd() @[short: C]
	jobs      int    = 1    @[short: j]
}

pub fn (args Args) execute_rule(rule string) !bool {
	if args.directory != os.getwd() {
		os.chdir(args.directory) or { return error('vmake: *** Can not change directory. Stop.') }
	}
	rules := Rules{}
	$for method in Rules.methods {
		mut method_name := arrays.find_first[string](method.attrs, fn (e string) bool {
			return e.starts_with('name: ')
		}) or { method.name }
		if method_name.starts_with('name :') {
			method_name = method_name.after('name: ')
		}
		if method.name == rule {
			mut really_execute := false
			if _ := arrays.find_first[string](method.attrs, fn (e string) bool {
				return e.starts_with('phony')
			})
			{
				really_execute = true
			} else if deps := arrays.find_first[string](method.attrs, fn (e string) bool {
				return e.starts_with('deps: ')
			})
			{
				deps_ := deps.after('deps: ').fields()
				really_execute = args.check_and_run_deps(rule, deps_)!
			}
			if really_execute {
				rules.$method(args) or { return error('vmake: *** [${rule}] Error:\n${err}') }
				return true
			}
			return false
		}
	}
	if os.exists(rule) {
		return false
	}
	return error("vmake: *** No rule to make target '${rule}'.  Stop.")
}

pub fn (args Args) check_and_run_deps(rule string, deps []string) !bool {
	mut updated := false
	mut rule_stat := os.Stat{}
	$if windows {
		if tmp_stat := os.lstat(rule) {
			rule_stat = tmp_stat
		} else if tmp_stat := os.lstat(rule + '.exe') {
			rule_stat = tmp_stat
		} else {
			updated = true
		}
	} $else {
		if tmp_stat := os.lstat(rule) {
			rule_stat = tmp_stat
		} else {
			updated = true
		}
	}
	rule_mtime := rule_stat.mtime
	for dep in deps {
		mut dep_stat_set := true
		mut dep_stat := os.Stat{}
		$if windows {
			if tmp_stat := os.lstat(dep) {
				dep_stat = tmp_stat
			} else if tmp_stat := os.lstat(dep + '.exe') {
				dep_stat = tmp_stat
			} else {
				dep_stat_set = false
			}
		} $else {
			if tmp_stat := os.lstat(dep) {
				dep_stat = tmp_stat
			} else {
				dep_stat_set = false
			}
		}
		eprintln('Checking ${rule} with dep ${dep}...')
		res := args.execute_rule(dep) or { return error("${err}  Needed by '${rule}'.") }
		if res {
			eprintln('updated')
			updated = true
		}
		dep_mtime := dep_stat.mtime
		if dep_stat_set && dep_mtime > rule_mtime {
			updated = true
		}
	}
	return updated
}

pub fn (args Args) sh(cmd string) ! {
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

@[deps: 'vmake']
fn (r Rules) all(args Args) ! {
}

@[name: 'vmake'; deps: 'vmake.v	v.mod']
fn (r Rules) target(args Args) ! {
	args.sh(@VEXE + ' -prod .')!
}

@[phony]
fn (r Rules) fmt(args Args) ! {
	args.sh(@VEXE + ' fmt -w .')!
}
