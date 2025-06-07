import flag
import os

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
	if args.show_help {
		doc := flag.to_doc[Args]() or {
			eprintln('vmake: *** For some reason when creating the documentation')
			return
		}
		println(doc)
		rules := args.list_rules[Rules]()
		if rules.len != 0 {
			println('')
			println('Rules:')
			for rule, deps in rules {
				print('  ${rule}')
				if deps.len != 0 {
					println(' : ${deps.join(", ")}')
				} else {
					println('')
				}
			}
		}
		return
	}
	for rule in no_matches {
		args.execute_rule[Rules](rule) or {
			eprintln(err)
			exit(2)
		}
	}
}
