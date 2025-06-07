import os
import arrays
import time

struct Args {
	directory string = os.getwd() @[short: C]
	jobs      int    = 1    @[short: j]
	show_help bool @[long: help; short: h]
}

pub fn (args Args) list_rules[T]() map[string][]string {
	mut res := map[string][]string{}
	$for method in Rules.methods {
		mut method_name := arrays.find_first[string](method.attrs, fn (e string) bool {
			return e.starts_with('name: ')
		}) or { method.name }
		if method_name.starts_with('name: ') {
			method_name = method_name.after('name: ')
		}
		if _ := arrays.find_first[string](method.attrs, fn (e string) bool {
			return e.starts_with('phony')
		})
		{
			res[method_name] = []string{}
		} else if deps := arrays.find_first[string](method.attrs, fn (e string) bool {
			return e.starts_with('deps: ')
		})
		{
			res[method_name] = deps.after('deps: ').fields()
		}
	}
	return res
}

pub fn (args Args) execute_rule[T](rule string) !bool {
	if args.directory != os.getwd() {
		os.chdir(args.directory) or { return error('vmake: *** Can not change directory. Stop.') }
	}
	rules := T{}
	$for method in T.methods {
		mut method_name := arrays.find_first[string](method.attrs, fn (e string) bool {
			return e.starts_with('name: ')
		}) or { method.name }
		if method_name.starts_with('name: ') {
			method_name = method_name.after('name: ')
		}
		if method_name == rule {
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
				really_execute = args.check_and_run_deps[T](rule, deps_)!
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

pub fn (args Args) check_and_run_deps[T](rule string, deps []string) !bool {
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
		res := args.execute_rule[T](dep) or { return error("${err}  Needed by '${rule}'.") }
		if res {
			updated = true
		}
		dep_mtime := dep_stat.mtime
		if dep_stat_set && dep_mtime > rule_mtime {
			updated = true
		}
	}
	return updated
}

@[params]
struct ShParams {
	timeit      bool
	show_stdout bool = true
	show_cmd    bool = true
}

pub fn (args Args) sh(cmd string, opts ShParams) ! {
	if opts.show_cmd {
		println(cmd)
	}
	mut stopwatch := if opts.timeit { time.new_stopwatch() } else { time.StopWatch{} }
	res := os.execute_opt(cmd)!
	if opts.timeit {
		stopwatch.stop()
	}
	if opts.show_stdout {
		print(res.output)
	}
	if opts.timeit {
		eprintln('vmake: *** sh time ${stopwatch.elapsed()}')
	}
}
