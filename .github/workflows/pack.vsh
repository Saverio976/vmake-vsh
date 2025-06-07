import os

fn main() {
	mut files := os.ls('.')!
	files.sort_ignore_case()
	mut output_body := []string{}
	mut output_import := []string{}
	if licenses := os.read_lines('LICENSE') {
		output_import << '/*'
		for line in licenses {
			output_import << line
		}
		output_import << '*/'
	}
	for file in files {
		if file.ends_with('.v') {
			output_body << ''
			lines := os.read_lines(file)!
			for line in lines {
				if line.starts_with('import ') {
					if line !in output_import {
						output_import << line + '	// ' + file
					}
				} else {
					output_body << line
				}
			}
		}
	}
	output_import << output_body
	os.write_lines(arguments()[1], output_import)!
}
